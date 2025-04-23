import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';
import 'package:see_write_say/features/story/providers/story_reading_provider.dart';

class StoryReadingScreen extends StatefulWidget {
  final StoryDto story;

  const StoryReadingScreen({super.key, required this.story});

  @override
  State<StoryReadingScreen> createState() => _StoryReadingScreenState();
}

class _StoryReadingScreenState extends State<StoryReadingScreen> {
  late final StoryReadingProvider provider;

  @override
  void initState() {
    super.initState();
    provider = StoryReadingProvider();
    provider.initializeWithStory(widget.story);
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: _StoryReadingContent(
        storyId: widget.story.id,
        initialTitle: widget.story.title,
      ),
    );
  }
}

class _StoryReadingContent extends StatefulWidget {
  final int storyId;
  final String initialTitle;

  const _StoryReadingContent({
    super.key,
    required this.storyId,
    required this.initialTitle,
  });

  @override
  State<_StoryReadingContent> createState() => _StoryReadingContentState();
}

class _StoryReadingContentState extends State<_StoryReadingContent> {
  bool _isFirstLoad = true;
  String _selectedLang = 'ko';

  final _langOptions = const {
    'ko': '한국어',
    'en': '영어',
    'ko_en': '한국어 + 영어',
    'en_ko': '영어 + 한국어',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      final provider = Provider.of<StoryReadingProvider>(
        context,
        listen: false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (provider.story?.content == null ||
            provider.story!.content.isEmpty) {
          provider.loadStory(
            context: context,
            id: widget.storyId,
            lang: _selectedLang,
            autoSpeak: false,
          );
        }
      });
      _isFirstLoad = false;
    }
  }

  void _fetchStory() {
    final provider = Provider.of<StoryReadingProvider>(context, listen: false);
    provider.loadStory(
      context: context,
      id: widget.storyId,
      lang: _selectedLang,
      autoSpeak: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryReadingProvider>();
    final story = provider.story;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          story?.title ?? widget.initialTitle,
          style: const TextStyle(fontSize: 20),
        ),
      ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : story == null || story.content.isEmpty
              ? const Center(child: Text("스토리를 불러올 수 없습니다."))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 언어 선택
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedLang,
                    items: _langOptions.entries
                        .map((entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value != _selectedLang) {
                        setState(() {
                          _selectedLang = value;
                        });
                        _fetchStory();
                      }
                    },
                  ),
                ],
              ),


              // 📣 자동 읽기 섹션
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.isSpeaking
                          ? () {
                        debugPrint("[중지 버튼] 클릭됨");
                        provider.stopSpeaking();
                      }
                          : () {
                        debugPrint("[자동 읽기 시작] 버튼 클릭됨");
                        provider.speakFromCurrent();
                      },
                      icon: Icon(provider.isSpeaking ? Icons.stop : Icons.volume_up),
                      label: Text(provider.isSpeaking ? "중지" : "자동 읽기"),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        provider.isPaused
                            ? Icons.play_arrow
                            : provider.isSpeaking
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        debugPrint("[재생/일시정지 버튼]");
                        if (provider.isPaused) {
                          provider.resumeSpeaking();
                        } else if (provider.isSpeaking) {
                          provider.pauseSpeaking();
                        } else {
                          provider.speakFromCurrent();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () {
                        debugPrint("[정지 버튼] 클릭됨");
                        provider.stopSpeaking();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        provider.goToPreviousParagraph();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        provider.goToNextParagraph();
                      },
                    ),
                  ],
                ),
              ),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => provider.togglePlayRecording(context),
                    icon: Icon(provider.isPlaying ? Icons.stop : Icons.play_circle_fill),
                    label: Text(provider.isPlaying ? "재생 중지" : "녹음 읽기"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => provider.toggleRecording(context),
                    icon: Icon(provider.isRecording ? Icons.stop_circle : Icons.mic),
                    label: Text(provider.isRecording ? "녹음 중지" : "녹음하기"),
                  ),
                ],
              ),



              // 📖 문단 리스트
              Expanded(
                child: ListView.builder(
                  itemCount: provider.paragraphs.length,
                  itemBuilder: (context, index) {
                    final para = provider.paragraphs[index];
                    final isCurrent = index == provider.currentIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.yellow.shade100 : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          para,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.black : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        )

    );
  }
}
