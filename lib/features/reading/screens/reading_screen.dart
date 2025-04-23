import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/features/reading/providers/reading_provider.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:see_write_say/core/presentation/components/common/common_image_viewer.dart';
import 'package:see_write_say/core/presentation/theme/text_styles.dart';
import 'package:see_write_say/core/presentation/components/audio/audio_control_bar.dart';

class ReadingScreen extends StatefulWidget {
  final String? sentence;
  final ImageDto? imageDto;

  const ReadingScreen({super.key, this.sentence, this.imageDto});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final ReadingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ReadingProvider();
    Future.microtask(() => _provider.initialize(
      context,
      widget.sentence ?? '',
      imageDto: widget.imageDto,
    ));
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: const ReadingContent(),
    );
  }
}

class ReadingContent extends StatelessWidget {
  const ReadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final isFromWriting = provider.sentence.isNotEmpty;
    final isFromPicture = provider.imageDto != null &&
        provider.imageDto!.path.isNotEmpty &&
        provider.sentence.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isFromWriting) {
              NavigationHelpers.goToWritingScreen(
                context,
                provider.imageDto!,
                sentence: provider.sentence,
              );
            } else if (isFromPicture) {
              NavigationHelpers.goToPictureScreen(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '읽기 연습', style: kHeadingTextStyle),
              TextSpan(
                text: ' (${provider.feedbackReadingRemainingCount})',
                style: kSubtitleTextStyle,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => NavigationHelpers.goToHistoryReadingScreen(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isFromPicture)
                CommonImageViewer(
                  imagePath: provider.imageDto!.path,
                  height: 200,
                  borderRadius: 12,
                ),
              if (isFromWriting) ...[
                const SizedBox(height: 8),
                const Text("작문 완료한 문장입니다", style: kBodyTextStyle),
                const SizedBox(height: 6),
                Text('"${provider.sentence}"', textAlign: TextAlign.center, style: kSubtitleTextStyle),
              ],
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.sentence.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: provider.speakSentence,
                      icon: const Icon(Icons.volume_up),
                      label: const Text("미리 들어보기"),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: provider.isRecording
                        ? provider.stopRecording
                        : provider.startRecording,
                    icon: Icon(provider.isRecording ? Icons.stop : Icons.mic),
                    label: Text(provider.isRecording ? "중지" : "읽기 시작"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              if (provider.isRecording) ...[
                const SizedBox(height: 12),
                const Text(
                  "🔴 녹음 중입니다...",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ],

              const SizedBox(height: 16),

              AudioControlBar(
                position: provider.position,
                duration: provider.duration,
                isPlaying: provider.isPlayingFile(provider.currentFilePath),
                isPaused: provider.isPausedFile(provider.currentFilePath),
                onPlayPause: () => provider.playMyVoiceRecording(provider.currentFilePath),
                onStop: provider.stopMyVoicePlayback,
                onSeek: provider.seekTo,
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: provider.isPlayable &&
                    !provider.isPlayingFile(provider.currentFilePath) &&
                    !provider.isRecording
                    ? () => provider.evaluatePronunciation(context)
                    : null,
                icon: const Icon(Icons.rate_review),
                label: const Text("피드백 받기"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.indigo),
                ),
              ),

              const SizedBox(height: 20),
              if (provider.showResult)
                Text(provider.feedback, style: kBodyTextStyle),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => NavigationHelpers.goToPictureScreen(context),
                child: const Text("처음 화면으로 돌아가기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}