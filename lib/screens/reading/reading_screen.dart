import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/providers/reading/reading_provider.dart';

class ReadingScreen extends StatelessWidget {
  final String? sentence;

  const ReadingScreen({super.key, this.sentence});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReadingProvider()..initialize(sentence ?? ''),
      child: const ReadingContent(),
    );
  }
}

class ReadingContent extends StatelessWidget {
  const ReadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("리딩 연습")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("읽을 문장:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                '"${provider.sentence}"',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text("문장을 소리내어 읽어보세요", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: provider.speak,
                icon: const Icon(Icons.volume_up),
                label: const Text("문장 듣기 (TTS)"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: provider.startListening,
                icon: Icon(provider.isListening ? Icons.stop : Icons.mic),
                label: Text(provider.isListening ? "중지" : "읽기 시작"),
              ),
              if (provider.showResult) ...[
                const SizedBox(height: 30),
                const Text("내가 말한 내용:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(provider.recognizedText, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Text("정확도: ${(provider.accuracy * 100).toStringAsFixed(1)}%"),
                const SizedBox(height: 10),
                Text(provider.feedback),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    provider.disposeTTS();
                  },
                  child: const Text("처음 화면으로 돌아가기"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
