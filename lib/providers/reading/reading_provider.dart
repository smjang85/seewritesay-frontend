import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:SeeWriteSay/models/image_model.dart';

class ReadingProvider extends ChangeNotifier {
  // 기본 상태값
  String sentence = '';
  ImageModel? imageModel;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool get isPlayingMyVoice => _myVoicePlayer.playing;
  bool get isPlayingHistory => _historyPlayer.playing;

  String currentFilePath = '';
  String? currentlyPlayingHistory;

  List<String> recordedPaths = [];

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration _pausedPosition = Duration.zero;

  // 도구들
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _myVoicePlayer = AudioPlayer();
  final AudioPlayer _historyPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;

  bool showResult = false;
  double accuracy = 0.0;
  String feedback = '';

  // 초기화
  Future<void> initialize(String sentence, {ImageModel? imageModel}) async {
    this.sentence = sentence;
    this.imageModel = imageModel;

    await _recorder.openRecorder();
    await _myVoicePlayer.setLoopMode(LoopMode.off);
    await _historyPlayer.setLoopMode(LoopMode.off);

    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(".aac"))
        .toList();

    final imageId = imageModel?.id.toString() ?? '';
    final imageName = imageModel?.name.replaceAll(RegExp(r'\.\w+$'), '') ?? '';

    recordedPaths = files
        .map((f) => f.path.split('/').last.replaceAll('.aac', ''))
        .where((name) => name.startsWith('${imageId}_${imageName}_'))
        .toList();

    notifyListeners();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // 녹음 시작
  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _isRecording = true;
    notifyListeners();

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final formatted = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
    final fileName = '${imageModel?.id}_${imageModel?.name.split('.').first}_$formatted';

    currentFilePath = '${dir.path}/$fileName.aac';

    await _recorder.startRecorder(toFile: currentFilePath);
  }

  // 녹음 종료
  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    _isRecording = false;

    final fileName = currentFilePath.split('/').last.replaceAll('.aac', '');
    _updateHistory(fileName);

    showResult = true;
    notifyListeners();
  }

  // 음성 피드백 평가
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

  // 내 음성 듣기
  Future<void> playMyVoiceRecording(String filePath) async {
    await _myVoicePlayer.stop();
    await _myVoicePlayer.setFilePath(filePath);
    await _myVoicePlayer.play();
    notifyListeners();
  }

  // 히스토리 재생
  Future<void> playHistoryRecording(String filePath) async {
    if (currentlyPlayingHistory == filePath && _historyPlayer.playing) {
      await pauseHistoryRecording();
      return;
    }

    if (currentlyPlayingHistory != filePath) {
      await stopHistoryRecording();
      await _historyPlayer.setFilePath(filePath);
    }

    currentlyPlayingHistory = filePath;
    await _historyPlayer.play();

    _positionSubscription?.cancel();
    _positionSubscription = _historyPlayer.positionStream.listen((pos) {
      position = pos;
      duration = _historyPlayer.duration ?? Duration.zero;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> pauseHistoryRecording() async {
    _pausedPosition = position;
    await _historyPlayer.pause();
    notifyListeners();
  }

  Future<void> resumeHistoryRecording() async {
    if (currentlyPlayingHistory == null) return;
    await _historyPlayer.seek(_pausedPosition);
    await _historyPlayer.play();
    notifyListeners();
  }

  Future<void> stopHistoryRecording() async {
    await _historyPlayer.stop();
    currentlyPlayingHistory = null;
    _pausedPosition = Duration.zero;
    notifyListeners();
  }

  // 재생 여부 확인
  bool isPlayingHistoryFile(String fileName) =>
      _historyPlayer.playing && (currentlyPlayingHistory?.contains(fileName) ?? false);

  // 프로그레스바 시크
  void seekTo(Duration value) async {
    await _myVoicePlayer.seek(value);
  }

  // 히스토리 삭제
  Future<void> deleteHistoryItem(String fileName) async {
    recordedPaths.remove(fileName);
    notifyListeners();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.aac');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 최신 히스토리 추가
  void _updateHistory(String fileName) {
    recordedPaths.insert(0, fileName);
    if (recordedPaths.length > 2) {
      recordedPaths.removeLast();
    }
    notifyListeners();
  }

  // 해제
  @override
  void dispose() {
    _recorder.closeRecorder();
    _myVoicePlayer.dispose();
    _historyPlayer.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
