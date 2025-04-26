import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool _isPaused = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  VoidCallback? _onChange;
  VoidCallback? _onComplete;
  VoidCallback? _onPlayStarted;
  VoidCallback? _onPlayStopped;

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get isPlaying => _isPlaying && !_isPaused;

  void setCallbacks({
    VoidCallback? onChange,
    VoidCallback? onComplete,
    VoidCallback? onPlayStarted,
    VoidCallback? onPlayStopped,
  }) {
    _onChange = onChange;
    _onComplete = onComplete;
    _onPlayStarted = onPlayStarted;
    _onPlayStopped = onPlayStopped;

    _positionSub?.cancel();
    _positionSub = _player.positionStream.listen((pos) {
      _onChange?.call();
    });

    _stateSub?.cancel();
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _isPaused = false;
        _onPlayStopped?.call();
        _onComplete?.call();
      }
      _onChange?.call();
    });
  }

  Future<void> play(String fullPath) async {
    if (_isPlaying) {
      await stop(); // 중복 방지
    }

    await _player.stop();
    reset();

    await _player.setFilePath(fullPath);

    _isPlaying = true;
    _isPaused = false;
    _onPlayStarted?.call();
    _onChange?.call();

    await _player.play();
  }

  Future<void> pause() async {
    if (_isPlaying && !_isPaused) {
      _isPaused = true;
      await _player.pause();
      _onChange?.call();
    }
  }

  Future<void> resume() async {
    if (_isPlaying && _isPaused) {
      _isPaused = false;
      await _player.play();
      _onChange?.call();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    reset();
    _onPlayStopped?.call();
    _onChange?.call();
  }

  void reset() {
    _isPlaying = false;
    _isPaused = false;
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekForward([Duration offset = const Duration(seconds: 10)]) async {
    final target = position + offset;
    await _player.seek(target > duration ? duration : target);
  }

  Future<void> seekBackward([Duration offset = const Duration(seconds: 10)]) async {
    final target = position - offset;
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
  }
}
