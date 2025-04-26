import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/core/presentation/theme/text_styles.dart';
import 'package:see_write_say/features/story/dto/chapter_dto.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';
import 'package:see_write_say/features/story/providers/story_reading_provider.dart';

class StoryReadingScreen extends StatefulWidget {
  final StoryDto? story;
  final ChapterDto? chapter;

  const StoryReadingScreen({
    super.key,
    this.story,
    this.chapter,
  }) : assert(story != null || chapter != null, 'story 또는 chapter 중 하나는 필수');

  @override
  State<StoryReadingScreen> createState() => _StoryReadingScreenState();
}

class _StoryReadingScreenState extends State<StoryReadingScreen> {
  late final StoryReadingProvider provider;

  @override
  void initState() {
    super.initState();
    provider = StoryReadingProvider();
    provider.initialize(story: widget.story, chapter: widget.chapter);
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyId = widget.story?.id ?? widget.chapter!.storyId;
    final title = widget.story?.title ?? widget.chapter!.title;

    return ChangeNotifierProvider.value(
      value: provider,
      child: _StoryReadingContent(
        storyId: storyId,
        chapterId: widget.chapter?.id,
        initialTitle: title,
      ),
    );
  }
}

class _StoryReadingContent extends StatefulWidget {
  final int storyId;
  final int? chapterId;
  final String initialTitle;

  const _StoryReadingContent({
    required this.storyId,
    required this.initialTitle,
    this.chapterId,
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
        provider.loadStory(
          context: context,
          id: widget.storyId,
          chapterId: widget.chapterId,
          lang: _selectedLang,
          autoSpeak: false,
        );
      });
      _isFirstLoad = false;
    }
  }

  void _fetchStory() {
    final provider = Provider.of<StoryReadingProvider>(context, listen: false);
    provider.loadStory(
      context: context,
      id: widget.storyId,
      chapterId: widget.chapterId,
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
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${story?.title ?? widget.initialTitle}', style: kHeadingTextStyle),
            ],
          ),
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
                      setState(() => _selectedLang = value);
                      _fetchStory();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 🔊 TTS 및 녹음 제어
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: provider.isSpeaking
                      ? provider.stopSpeaking
                      : provider.speakFromCurrent,
                  icon: Icon(
                    provider.isSpeaking ? Icons.stop : Icons.volume_up,
                  ),
                  label: Text(provider.isSpeaking ? "중지" : "자동 읽기"),
                ),
                IconButton(
                  icon: Icon(
                    provider.isPaused
                        ? Icons.play_arrow
                        : provider.isSpeaking
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: () {
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
                  icon: const Icon(Icons.skip_previous),
                  onPressed: provider.goToPreviousParagraph,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: provider.goToNextParagraph,
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () => provider.toggleRecording(context),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () => provider.togglePlayRecording(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 📖 본문
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
                          fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
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
      ),
    );

  }
}
