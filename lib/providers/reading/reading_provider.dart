
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:SeeWriteSay/models/image_model.dart';

class ReadingProvider extends ChangeNotifier {
  String sentence = '';
  ImageModel? imageModel;

  bool _isRecording = false;
  String currentFilePath = '';
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration _pausedPosition = Duration.zero;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;

  bool showResult = false;
  double accuracy = 0.0;
  String feedback = '';

  String? _currentFile;
  bool _isPlaying = false;
  bool _isPaused = false;

  /// 초기화
  Future<void> initialize(String sentence, {ImageModel? imageModel}) async {
    this.sentence = sentence;
    this.imageModel = imageModel;

    await _recorder.openRecorder();
    await _audioPlayer.setLoopMode(LoopMode.off);

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      position = pos;
      duration = _audioPlayer.duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _isPaused = false;
        _currentFile = null;
        position = Duration.zero;
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// 녹음 시작
  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    // 🔁 재생 상태 초기화

    _isPlaying = false;
    _isPaused = false;
    position = Duration.zero;
    duration = Duration.zero;
    _pausedPosition = Duration.zero;
    currentFilePath = '';
    _isRecording = true;
    notifyListeners();

    await _audioPlayer.stop();

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName =
        '${imageModel?.id}_${imageModel?.name.split('.').first}_${_formatDateTime(now)}';

    currentFilePath = '${dir.path}/$fileName.aac';
    await _recorder.startRecorder(toFile: currentFilePath);
  }


  /// 녹음 종료
  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    _isRecording = false;
    showResult = true;
    notifyListeners();
  }

  bool get isRecording => _isRecording;

  /// 피드백
  void evaluateRecording(String inputText) {
    final similarity = sentence.similarityTo(inputText);
    accuracy = similarity;
    feedback = (similarity > 0.8)
        ? '잘 읽었어요!'
        : (similarity > 0.5)
        ? '조금 더 정확히 읽어보세요.'
        : '다시 한 번 도전해볼까요?';
    notifyListeners();
  }

  bool isPlayingFile(String filePath) =>
      _isPlaying && !_isPaused && _currentFile == filePath;

  bool isPausedFile(String filePath) =>
      _isPaused && _currentFile == filePath;

  Future<void> playMyVoiceRecording(String filePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fullPath =
    filePath.contains(dir.path) ? filePath : '${dir.path}/$filePath';

    if (_isPlaying && _currentFile == filePath) {
      if (_isPaused) {
        _isPaused = false;
        _isPlaying = true;
        notifyListeners();
        await _audioPlayer.play();
      } else {
        _pausedPosition = await _audioPlayer.position;
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

    await _audioPlayer.setFilePath(fullPath);
    _currentFile = filePath;
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();

    await _audioPlayer.play();
  }

  Future<void> stopMyVoicePlayback() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _isPaused = false;
    position = Duration.zero;
    _currentFile = null;
    notifyListeners();
  }

  Future<void> seekTo(Duration value) async {
    if (duration > Duration.zero) {
      await _audioPlayer.seek(value);
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime now) {
    return '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _positionSub?.cancel();
    super.dispose();
  }
}
