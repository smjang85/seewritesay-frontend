import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/foundation.dart';

enum RecorderState {
  idle,
  recording,
  stopped,
  playing,
}

class RecorderController {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;
  bool _hasRecording = false;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get shouldBlockTts => _isRecording || _isPlaying;
  bool get hasRecording => _hasRecording;

  VoidCallback? _onRecordingComplete;

  void setOnRecordingComplete(VoidCallback callback) {
    _onRecordingComplete = callback;
  }

  Future<void> init() async {
    try {
      if (_recorder.isStopped) {
        await _recorder.openRecorder();
        debugPrint("🟢 Recorder 초기화 및 오픈 완료");
      } else {
        debugPrint("ℹ️ Recorder 이미 열려 있음");
      }
    } catch (e, stack) {
      debugPrint("❗ init() 오류: $e\n$stack");
    }
  }

  Future<void> initializeWithPath(String path) async {
    try {
      debugPrint("📁 initializeWithPath() 호출됨. path: $path");

      if (!_recorder.isStopped) {
        debugPrint("🛑 기존 Recorder 닫기 시도");
        await _recorder.closeRecorder();
      }

      await _recorder.openRecorder();
      _filePath = path;

      final file = File(_filePath!);
      _hasRecording = file.existsSync();
      debugPrint("📄 파일 존재 여부: $_hasRecording");
    } catch (e, stack) {
      debugPrint("❗ initializeWithPath 오류: $e\n$stack");
    }
  }

  Future<void> start(String path) async {
    try {
      debugPrint("▶️ start() 호출됨. path: $path");

      if (!_recorder.isStopped && !_recorder.isRecording) {
        debugPrint("📛 Recorder 상태 불안정. 중지 시도 중...");
        await _recorder.stopRecorder();
      }

      _isRecording = true;
      _filePath = path;

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      debugPrint("🎙️ 녹음 시작됨: $_filePath");
    } catch (e, stack) {
      _isRecording = false;
      debugPrint("❗ startRecorder 오류: $e\n$stack");
      rethrow;
    }
  }

  Future<void> stop() async {
    debugPrint("⏹️ stop() 호출됨. isRecording=$_isRecording");

    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
        debugPrint("🔚 Recorder 정상 종료됨");
      } else {
        debugPrint("⚠️ Recorder는 이미 중지된 상태");
      }
    } catch (e, stack) {
      debugPrint("❗ stopRecorder 오류: $e\n$stack");
    } finally {
      _isRecording = false;

      if (_filePath != null) {
        final file = File(_filePath!);
        _hasRecording = file.existsSync();
        debugPrint("📦 녹음 파일 존재 여부: $_hasRecording ($_filePath)");
      } else {
        _hasRecording = false;
        debugPrint("❌ 파일 경로 없음. 녹음 파일 존재 확인 불가");
      }

      _onRecordingComplete?.call();
    }
  }

  Future<void> playRecording(String path) async {
    debugPrint("📂 playRecording() 호출됨. path: $path");

    final file = File(path);
    if (!file.existsSync()) {
      debugPrint("🚫 녹음 파일 존재하지 않음: $path");
      return;
    }

    debugPrint("✅ 녹음 파일 존재함");

    if (_recorder.isRecording) {
      debugPrint("🔁 녹음 중 -> 재생 위해 중단 시도");
      await stop();
    }

    // 실제 재생 로직은 외부에서 처리된다고 가정
    _isPlaying = true;
    debugPrint("🔊 재생 시작됨");
  }

  void stopPlayback() {
    debugPrint("🛑 stopPlayback() 호출됨");
    _isPlaying = false;
  }

  void onPlayStarted() {
    _isPlaying = true;
    debugPrint("▶️ 재생 상태 진입");
  }

  void onPlayStopped() {
    _isPlaying = false;
    debugPrint("⏹️ 재생 종료됨");
  }

  Future<void> stopAll() async {
    debugPrint("🛑 stopAll() 호출됨");

    if (_isPlaying) {
      debugPrint("🟠 재생 중단");
      stopPlayback();
    }
    if (_isRecording) {
      debugPrint("🟣 녹음 중단");
      await stop();
    }
  }

  void resetRecorder() {
    debugPrint("♻️ resetRecorder() 호출됨");

    try {
      _recorder.closeRecorder();
    } catch (e) {
      debugPrint("❗ Recorder 닫기 중 오류 (무시됨): $e");
    }

    _recorder = FlutterSoundRecorder(); // 새로운 인스턴스 할당
    debugPrint("🔄 Recorder 인스턴스 재설정 완료");
  }

  void dispose() {
    debugPrint("🧹 dispose() 호출됨");
    stopAll();
    _recorder.closeRecorder();
    debugPrint("💨 Recorder 자원 해제 완료");
  }
}
