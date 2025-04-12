import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/providers/reading/reading_provider.dart';
import 'package:SeeWriteSay/widgets/common_image_viewer.dart';

class ReadingScreen extends StatefulWidget {
  final String? sentence;
  final ImageModel? imageModel;

  const ReadingScreen({super.key, this.sentence, this.imageModel});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final ReadingProvider _provider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _provider = ReadingProvider();

    Future.microtask(() async {
      await _provider.initialize(
        widget.sentence ?? '',
        imageModel: widget.imageModel,
      );
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
    final isFromPicture = provider.imageModel != null &&
        provider.imageModel!.path.isNotEmpty &&
        provider.sentence.isEmpty;

    final isPlayable = provider.currentFilePath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isFromWriting) {
              NavigationHelpers.goToWritingScreen(
                context,
                provider.imageModel!,
                sentence: provider.sentence,
              );
            } else if (isFromPicture) {
              NavigationHelpers.goToPictureScreen(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text("리딩 연습"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              NavigationHelpers.goToHistoryReadingScreen(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isFromPicture)
              CommonImageViewer(
                imagePath: provider.imageModel!.path,
                height: 200,
                borderRadius: 12,
              ),
            if (isFromWriting) ...[
              const SizedBox(height: 8),
              const Text(
                "작문 완료한 문장입니다",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '"${provider.sentence}"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ],

            const SizedBox(height: 20),

            /// 🎤 읽기 시작 / 중지
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

            const SizedBox(height: 16),

            /// 🔊 재생 + 정지 버튼 (항상 노출)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final filePath = provider.currentFilePath;
                    if (!provider.isPlayingFile(filePath)) {
                      await provider.playMyVoiceRecording(filePath);
                    } else if (!provider.isPausedFile(filePath)) {
                      await provider.playMyVoiceRecording(filePath); // 일시정지
                    } else {
                      await provider.playMyVoiceRecording(filePath); // 재개
                    }
                  },
                  child: Text(
                    provider.isPlayingFile(provider.currentFilePath)
                        ? '일시 정지'
                        : '재생',
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isPlayable &&
                      provider.isPlayingFile(provider.currentFilePath)
                      ? () => provider.stopMyVoicePlayback()
                      : null,
                  child: const Icon(Icons.stop),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// 🎚️ 프로그레스 바 (항상 노출, 단 비활성화)
            Slider(
              value: provider.position.inMilliseconds
                  .clamp(0, provider.duration.inMilliseconds.toDouble())
                  .toDouble(),
              max: provider.duration.inMilliseconds.toDouble().clamp(
                  1, double.infinity),
              onChanged: isPlayable
                  ? (value) {
                provider.seekTo(Duration(milliseconds: value.toInt()));
              }
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatTime(provider.position),
                    style: const TextStyle(fontSize: 12)),
                Text(_formatTime(provider.duration),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 20),
            if (provider.showResult) Text(provider.feedback),
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
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
