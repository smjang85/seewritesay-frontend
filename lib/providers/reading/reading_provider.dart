import 'dart:async';
import 'dart:io';
import 'package:SeeWriteSay/constants/constants.dart';
import 'package:SeeWriteSay/dto/image_dto.dart';
import 'package:SeeWriteSay/services/api/feedback/user_feedback_api_service.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/utils/dialog_popup_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';

class ReadingProvider extends ChangeNotifier {
  String sentence = '';
  ImageDto? imageDto;

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

  int _feedbackReadingRemainingCount = -1;

  String get feedbackReadingRemainingCount {
    if (_feedbackReadingRemainingCount == -1) return '조회중';
    if (_feedbackReadingRemainingCount == 0) return '오늘은 모두 사용했어요';
    return '$_feedbackReadingRemainingCount회 남음';
  }

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speakSentence() async {
    if (sentence.isEmpty) return;
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(sentence);
  }

  /// 초기화
  Future<void> initialize(BuildContext context, String sentence, {ImageDto? imageDto}) async {
    this.sentence = sentence;
    this.imageDto = imageDto;

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

    if (imageDto?.id != null) {
      final counts = await UserFeedbackApiService.fetchRemainingCounts(imageDto!.id);
      _feedbackReadingRemainingCount = counts.readingRemainingCount;
    }

    notifyListeners();
  }

  /// 녹음 시작
  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    await _audioPlayer.stop();

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName =
        '${imageDto?.id}_${imageDto?.name.split('.').first}_${_formatDateTime(now)}';
    final newFilePath = '${dir.path}/$fileName.aac';

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
    f.path.endsWith('.aac') &&
        imageDto != null &&
        f.path.contains('${imageDto!.id}_'))
        .toList();

    if (files.length >= Constants.readingRecordLength) {
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      final toDelete = files.sublist(0, files.length - 1);
      for (var file in toDelete) {
        await file.delete();
      }
    }

    _isPlaying = false;
    _isPaused = false;
    position = Duration.zero;
    duration = Duration.zero;
    _pausedPosition = Duration.zero;
    currentFilePath = newFilePath;
    _isRecording = true;
    notifyListeners();

    await _recorder.startRecorder(toFile: currentFilePath);
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    await _recorder.stopRecorder();
    _isRecording = false;
    showResult = true;
    notifyListeners();
  }

  bool get isRecording => _isRecording;

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

  Future<void> evaluatePronunciation(BuildContext context) async {
    if (currentFilePath.isEmpty) return;

    try {
      final imageId = imageDto?.id;
      if (imageId == null) {
        CommonLogicService.showSnackBarWithDuration(context, "❌ 이미지 정보가 없습니다.");
        return;
      }

      final remaining = (await UserFeedbackApiService.fetchRemainingCounts(imageId)).readingRemainingCount;
      if (remaining <= 0) {
        CommonLogicService.showSnackBarWithDuration(context, "📛 피드백 횟수를 모두 사용하였습니다.");
        return;
      }

      await DialogPopupHelper.evaluatePronunciationDialog(
        context: context,
        filePath: currentFilePath,
        imageId: imageId,
        sentence: sentence,
      );

      await UserFeedbackApiService.decreaseReadingFeedbackCount(context, imageId);
      _feedbackReadingRemainingCount--;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ 발음 평가 실패: $e");
      CommonLogicService.showErrorSnackBar(context, e);
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime now) {
    return '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
  }

  bool get isPlayable {
    return currentFilePath.isNotEmpty && File(currentFilePath).existsSync();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _positionSub?.cancel();
    super.dispose();
  }
}
