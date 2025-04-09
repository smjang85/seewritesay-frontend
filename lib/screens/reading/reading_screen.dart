import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/providers/reading/reading_provider.dart';
import 'package:SeeWriteSay/widgets/common_image_viewer.dart';

class ReadingScreen extends StatelessWidget {
  final String? sentence;
  final String? imagePath;

  const ReadingScreen({super.key, this.sentence, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReadingProvider()
        ..initialize(sentence ?? '', imagePath: imagePath),
      child: const ReadingContent(),
    );
  }
}

class ReadingContent extends StatelessWidget {
  const ReadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final isFromPicture = provider.imagePath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("리딩 연습")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            if (isFromPicture)
              Center(
                child: CommonImageViewer(
                  imagePath: provider.imagePath,
                  height: 200, // 작문과 동일하게 고정
                  borderRadius: 12,
                ),
              )
            else if (provider.sentence.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "작문 완료한 문장입니다",
                style: TextStyle(
                  fontSize: 18, // 조금 더 크게
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // 더 진한 회색 계열
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
            ],

            const SizedBox(height: 16),

            // ✅ 스크롤 가능한 아래 영역
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: provider.isListening
                          ? provider.stopListening
                          : provider.startListening,
                      icon: Icon(provider.isListening ? Icons.stop : Icons.mic),
                      label: Text(provider.isListening ? "중지" : "읽기 시작"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (provider.recordedFilePath.isNotEmpty) ...[
                      ElevatedButton.icon(
                        onPressed: provider.playRecording,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("내 음성 듣기"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: provider.duration.inMilliseconds == 0
                            ? 0
                            : provider.position.inMilliseconds /
                            provider.duration.inMilliseconds,
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blueAccent,
                      ),
                    ],

                    if (provider.showResult) ...[
                      const SizedBox(height: 30),
                      const Text("내가 말한 내용:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(provider.recognizedText,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Text(
                          "정확도: ${(provider.accuracy * 100).toStringAsFixed(1)}%"),
                      const SizedBox(height: 10),
                      Text(provider.feedback),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(
                              context, (route) => route.isFirst);
                          provider.disposeResources();
                        },
                        child: const Text("처음 화면으로 돌아가기"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

