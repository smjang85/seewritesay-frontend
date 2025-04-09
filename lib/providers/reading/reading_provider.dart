import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReadingProvider extends ChangeNotifier {
  String sentence = '';
  String imagePath = '';
  String recognizedText = '';
  String feedback = '';
  double accuracy = 0.0;
  bool isListening = false;
  bool showResult = false;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  String recordedFilePath = '';
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  StreamSubscription? _playerSubscription;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void initialize(String sentence, {String? imagePath}) async {
    this.sentence = sentence;
    this.imagePath = imagePath ?? '';
    await _recorder.openRecorder();
    await _player.openPlayer();
    notifyListeners();
  }

  Future<void> speak() async {
    await _flutterTts.speak(sentence);
  }

  Future<void> startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    isListening = true;
    showResult = false;
    recognizedText = '';
    feedback = '';
    accuracy = 0.0;
    notifyListeners();

    final dir = await getApplicationDocumentsDirectory();
    recordedFilePath = '${dir.path}/recording.aac';
    await _recorder.startRecorder(toFile: recordedFilePath);

    await _speech.listen(onResult: (result) {
      recognizedText = result.recognizedWords;
      notifyListeners();
    });
  }

  Future<void> stopListening() async {
    await _speech.stop();
    await _recorder.stopRecorder();

    isListening = false;
    _calculateAccuracy();
    showResult = true;
    notifyListeners();
  }

  void _calculateAccuracy() {
    accuracy = sentence.similarityTo(recognizedText);
    if (accuracy > 0.8) {
      feedback = '잘 읽었어요!';
    } else if (accuracy > 0.5) {
      feedback = '조금 더 정확히 읽어보세요.';
    } else {
      feedback = '다시 한 번 도전해볼까요?';
    }
  }

  Future<void> playRecording() async {
    if (recordedFilePath.isEmpty) return;

    await _player.startPlayer(
      fromURI: recordedFilePath,
      whenFinished: () {
        position = Duration.zero;
        notifyListeners();
      },
    );

    _playerSubscription = _player.onProgress!.listen((event) {
      position = event.position;
      duration = event.duration;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _playerSubscription?.cancel();
    super.dispose();
  }

  void disposeResources() {
    _flutterTts.stop();
    _speech.cancel();
    _recorder.stopRecorder();
    _player.stopPlayer();
    _playerSubscription?.cancel();
  }
}