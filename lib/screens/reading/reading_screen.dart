import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class ReadingScreen extends StatefulWidget {
  final String? sentence;

  const ReadingScreen({super.key, this.sentence});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late FlutterTts _tts;
  late stt.SpeechToText _speech;

  bool _isListening = false;
  String _recognizedText = '';
  double _accuracy = 0.0;
  String _feedback = '';
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _speech = stt.SpeechToText();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
  }

  Future<void> _startListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _accuracy = 0.0;
      _feedback = '';
      _showResult = false;
    });

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );

    if (!available) {
      setState(() => _isListening = false);
      return;
    }

    _speech.listen(
      localeId: 'en_US',
      listenMode: stt.ListenMode.confirmation,
      listenFor: Duration(seconds: 6),
      pauseFor: Duration(seconds: 2),
      onResult: (result) {
        if (!result.finalResult) return;
        final spoken = result.recognizedWords;
        final accuracy = _calculateAccuracy(widget.sentence ?? '', spoken);
        setState(() {
          _recognizedText = spoken;
          _accuracy = accuracy;
          _feedback = _generateFeedback(accuracy);
          _showResult = true;
          _isListening = false;
        });
      },
    );
  }

  double _calculateAccuracy(String original, String spoken) {
    final originalWords = original.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').split(RegExp(r'\s+'));
    final spokenWords = spoken.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').split(RegExp(r'\s+'));

    if (originalWords.isEmpty || spokenWords.isEmpty) return 0.0;

    int matchCount = 0;
    for (final word in originalWords) {
      for (final spokenWord in spokenWords) {
        if (word.similarityTo(spokenWord) > 0.8) {
          matchCount++;
          break;
        }
      }
    }
    return matchCount / originalWords.length;
  }

  String _generateFeedback(double score) {
    if (score >= 0.95) return "✅ 완벽해요! 멋져요!";
    if (score >= 0.7) return "👌 거의 정확해요. 몇 단어만 더 연습해봐요.";
    return "🧐 다시 연습해보세요. 조금 더 정확하게!";
  }

  void _goBackToStart() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displaySentence = widget.sentence ?? '';

    return Scaffold(
      appBar: AppBar(title: Text("리딩 연습")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("읽을 문장:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                '"$displaySentence"',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Text("문장을 소리내어 읽어보세요", style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tts.speak(displaySentence),
                icon: Icon(Icons.volume_up),
                label: Text("문장 듣기 (TTS)"),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(_isListening ? "중지" : "읽기 시작"),
              ),
              if (_showResult) ...[
                SizedBox(height: 30),
                Text("내가 말한 내용:", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(_recognizedText, textAlign: TextAlign.center),
                SizedBox(height: 20),
                Text("정확도: ${(_accuracy * 100).toStringAsFixed(1)}%"),
                SizedBox(height: 10),
                Text(_feedback),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _goBackToStart,
                  child: Text("처음 화면으로 돌아가기"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
