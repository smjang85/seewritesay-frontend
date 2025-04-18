import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// 공통 오디오 재생/시크/정지 로직을 포함하는 베이스 프로바이더
abstract class BaseAudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  String? _currentFile;
  bool _isPlaying = false;
  bool _isPaused = false;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  String? get currentFile => _currentFile;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;

  bool isPlayingFile(String file) => _isPlaying && !_isPaused && _currentFile == file;
  bool isPausedFile(String file) => _isPaused && _currentFile == file;

  Future<void> initAudioPlayer() async {
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      position = pos;
      duration = _audioPlayer.duration ?? Duration.zero;
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _isPaused = false;
        _currentFile = null;
        position = Duration.zero;
        notifyListeners();
      }
    });
  }

  Future<void> playFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final fullPath = fileName.contains(dir.path) ? fileName : '${dir.path}/$fileName';

    if (_isPlaying && _currentFile == fileName) {
      if (_isPaused) {
        _isPaused = false;
        _isPlaying = true;
        notifyListeners();
        await _audioPlayer.play();
      } else {
        _isPaused = true;
        notifyListeners();
        await _audioPlayer.pause();
      }
      return;
    }

    await _audioPlayer.stop();
    _isPlaying = false;
    _isPaused = false;
    notifyListeners();

    try {
      await _audioPlayer.setFilePath(fullPath);
      _currentFile = fileName;
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ playFile error: $e');
    }
  }

  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _isPaused = false;
    _currentFile = null;
    position = Duration.zero;
    notifyListeners();
  }

  Future<void> seekTo(Duration value) async {
    if (duration > Duration.zero) {
      await _audioPlayer.seek(value);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }
}