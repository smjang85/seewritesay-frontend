// ✅ 리딩 Provider 정의
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class ReadingProvider extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String sentence = '';
  bool isListening = false;
  String recognizedText = '';
  double accuracy = 0.0;
  String feedback = '';
  bool showResult = false;

  Future<void> initialize(String sentenceText) async {
    sentence = sentenceText;
    await _tts.setLanguage("en-US");
  }

  Future<void> speak() async {
    await _tts.speak(sentence);
  }

  Future<void> startListening() async {
    if (isListening) {
      await _speech.stop();
      isListening = false;
      notifyListeners();
      return;
    }

    isListening = true;
    recognizedText = '';
    accuracy = 0.0;
    feedback = '';
    showResult = false;
    notifyListeners();

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        isListening = false;
        notifyListeners();
      },
    );

    if (!available) {
      isListening = false;
      notifyListeners();
      return;
    }

    _speech.listen(
      localeId: 'en_US',
      listenFor: Duration(seconds: 6),
      pauseFor: Duration(seconds: 2),
      onResult: (result) {
        if (!result.finalResult) return;
        final spoken = result.recognizedWords;
        final score = _calculateAccuracy(sentence, spoken);
        recognizedText = spoken;
        accuracy = score;
        feedback = _generateFeedback(score);
        showResult = true;
        isListening = false;
        notifyListeners();
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

  void reset() {
    recognizedText = '';
    accuracy = 0.0;
    feedback = '';
    showResult = false;
    notifyListeners();
  }

  void disposeTTS() {
    _tts.stop();
    _speech.stop();
  }
}