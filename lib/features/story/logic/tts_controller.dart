import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { stopped, speaking, paused }

class TtsController {
  final FlutterTts _tts = FlutterTts();
  TtsState _state = TtsState.stopped;
  Completer<void>? _currentCompleter;

  String? _pausedParagraph;

  /// 외부에서 상태 변경을 감지할 수 있는 콜백
  void Function(TtsState state)? onStateChanged;

  /// 한 문단 낭독 완료 후 실행될 콜백
  VoidCallback? onComplete;

  TtsController() {
    _initTTS();
  }

  TtsState get state => _state;

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    _pausedParagraph = text;
    final isEnglish = _detectEnglish(text);
    await _tts.setLanguage(isEnglish ? 'en-US' : 'ko-KR');
    await _tts.setSpeechRate(0.45);

    _setState(TtsState.speaking);
    _currentCompleter = Completer<void>();
    await _tts.speak(text);
    await _currentCompleter!.future;
  }

  Future<void> stop() async {
    await _tts.stop();
    _setState(TtsState.stopped);
    _completeIfPending();
  }

  Future<void> pause() async {
    await _tts.stop();
    _setState(TtsState.paused);
    _completeIfPending();
  }

  Future<void> resume() async {
    if (_pausedParagraph != null) {
      await speak(_pausedParagraph!);
    }
  }

  void _setState(TtsState newState) {
    _state = newState;
    onStateChanged?.call(_state);
  }

  void _completeIfPending() {
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete();
    }
  }

  void _initTTS() {
    _tts.setCompletionHandler(() {
      _setState(TtsState.stopped);
      _completeIfPending();
      if (onComplete != null) {
        onComplete!();
      }
    });
    _tts.setPauseHandler(() {
      _setState(TtsState.paused);
    });
    _tts.setContinueHandler(() {
      _setState(TtsState.speaking);
    });
    _tts.setErrorHandler((msg) {
      debugPrint("❌ TTS 오류: $msg");
      _setState(TtsState.stopped);
      _completeIfPending();
    });
  }

  bool _detectEnglish(String text) {
    final alpha = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    return alpha.length / text.length > 0.4;
  }

  void dispose() {
    _tts.stop();
    _tts.setCompletionHandler(() {});
    _tts.setPauseHandler(() {});
    _tts.setContinueHandler(() {});
    _tts.setErrorHandler((_) {});
  }
}
