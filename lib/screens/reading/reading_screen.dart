// 수정된 ReadingScreen (스크린쪽 전체)

import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/style/text_styles.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
    final isFromPicture =
        provider.imageModel != null &&
            provider.imageModel!.path.isNotEmpty &&
            provider.sentence.isEmpty;

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isFromPicture) ...[
              CommonImageViewer(
                imagePath: provider.imageModel!.path,
                height: 200,
                borderRadius: 12,
              ),
              const SizedBox(height: 8),
            ] else if (isFromWriting) ...[
              const Text(
                "작문 완료한 문장입니다",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '"${provider.sentence}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],

            ElevatedButton.icon(
              onPressed:
              provider.isRecording ? provider.stopRecording : provider.startRecording,
              icon: Icon(provider.isRecording ? Icons.stop : Icons.mic),
              label: Text(provider.isRecording ? "중지" : "읽기 시작"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: provider.isRecording || provider.currentFilePath.isEmpty
                  ? null
                  : () => provider.playMyVoiceRecording(provider.currentFilePath),
              icon: Icon(
                provider.isPlayingMyVoice ? Icons.stop : Icons.play_arrow,
              ),
              label: Text(provider.isPlayingMyVoice ? "정지" : "내 음성 듣기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
              ),
            ),

            if (provider.duration.inMilliseconds > 0) ...[
              Slider(
                value: provider.position.inMilliseconds / provider.duration.inMilliseconds,
                onChanged: (value) => provider.seekTo(
                  Duration(
                    milliseconds: (provider.duration.inMilliseconds * value).toInt(),
                  ),
                ),
              ),
            ],
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
}
