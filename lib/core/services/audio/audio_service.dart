import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart'; // VoidCallback 정의 포함

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  String? _currentFile;
  bool _isPlaying = false;
  bool _isPaused = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  VoidCallback? _onChange;
  VoidCallback? _onComplete;

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  String? get currentFile => _currentFile;

  bool isPlayingFile(String file) => _isPlaying && !_isPaused && _currentFile == file;
  bool isPausedFile(String file) => _isPaused && _currentFile == file;

  void setCallbacks({VoidCallback? onChange, VoidCallback? onComplete}) {
    _onChange = onChange;
    _onComplete = onComplete;

    _positionSub?.cancel();
    _positionSub = _player.positionStream.listen((_) => _onChange?.call());

    _stateSub?.cancel();
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        reset();
        _onComplete?.call();
      }
    });
  }

  Future<void> togglePlayback(String file, String fullPath) async {
    if (_isPlaying && _currentFile == file) {
      if (_isPaused) {
        _isPaused = false;
        _isPlaying = true;
        _onChange?.call();
        await _player.play();
      } else {
        _isPaused = true;
        _onChange?.call();
        await _player.pause();
      }
      return;
    }

    await _player.stop();
    reset();
    _onChange?.call();

    await _player.setFilePath(fullPath);
    _currentFile = file;
    _isPlaying = true;
    _isPaused = false;
    _onChange?.call();

    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    reset();
    _onChange?.call();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  void reset() {
    _isPlaying = false;
    _isPaused = false;
    _currentFile = null;
  }

  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
  }
}
