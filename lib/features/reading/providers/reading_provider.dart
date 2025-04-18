import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:see_write_say/core/helpers/format/format_helper.dart';
import 'package:see_write_say/core/providers/audio/base_audio_provider.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:see_write_say/app/constants/constants.dart';
import 'package:see_write_say/core/presentation/dialog/dialog_popup_helper.dart';
import 'package:see_write_say/core/presentation/helpers/snackbar_helper.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/features/reading/api/reading_api_service.dart';
import 'package:see_write_say/features/writing/api/writing_api_service.dart';

class ReadingProvider extends BaseAudioProvider {
  String sentence = '';
  ImageDto? imageDto;

  bool _isRecording = false;
  String currentFilePath = '';

  bool showResult = false;
  double accuracy = 0.0;
  String feedback = '';

  int _feedbackReadingRemainingCount = -1;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterTts _flutterTts = FlutterTts();

  String get feedbackReadingRemainingCount {
    if (_feedbackReadingRemainingCount == -1) return '조회중';
    if (_feedbackReadingRemainingCount == 0) return '오늘은 완료';
    return '$_feedbackReadingRemainingCount회 남음';
  }

  bool get isRecording => _isRecording;

  bool get isPlayable => currentFilePath.isNotEmpty && File(currentFilePath).existsSync();

  Future<void> initialize(BuildContext context, String sentence, {ImageDto? imageDto}) async {
    this.sentence = sentence;
    this.imageDto = imageDto;

    await _recorder.openRecorder();
    await initAudioPlayer();

    if (imageDto?.id != null) {
      final counts = await WritingApiService.fetchRemainingCounts(imageDto!.id);
      _feedbackReadingRemainingCount = counts.readingRemainingCount;
    }

    notifyListeners();
  }

  Future<void> speakSentence() async {
    if (sentence.isEmpty) return;
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(sentence);
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    await stopPlayback();

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName = '${imageDto?.id}_${FormatHelper.formatDateTime(now)}.aac';
    final newFilePath = '${dir.path}/$fileName';

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.aac') && imageDto != null && f.path.contains('${imageDto!.id}_'))
        .toList();

    if (files.length >= Constants.readingRecordLength) {
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      final toDelete = files.sublist(0, files.length - 1);
      for (var file in toDelete) {
        await file.delete();
      }
    }

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

  Future<void> playMyVoiceRecording(String filePath) async {
    await playFile(filePath);
  }

  Future<void> stopMyVoicePlayback() async {
    await stopPlayback();
  }

  Future<void> evaluatePronunciation(BuildContext context) async {
    if (currentFilePath.isEmpty) return;

    try {
      final imageId = imageDto?.id;
      if (imageId == null) {
        SnackbarHelper.show(context, "❌ 이미지 정보가 없습니다.");
        return;
      }

      final remaining = (await WritingApiService.fetchRemainingCounts(imageId)).readingRemainingCount;
      if (remaining <= 0) {
        SnackbarHelper.show(context, "📛 피드백 횟수를 모두 사용하였습니다.", seconds: 1);
        return;
      }

      await DialogPopupHelper.evaluatePronunciationDialog(
        context: context,
        filePath: currentFilePath,
        imageId: imageId,
        sentence: sentence,
      );

      await ReadingApiService.decreaseReadingFeedbackCount(imageId);
      _feedbackReadingRemainingCount--;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ 발음 평가 실패: $e");
      SnackbarHelper.showError(context, e);
    }
  }


  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }
}