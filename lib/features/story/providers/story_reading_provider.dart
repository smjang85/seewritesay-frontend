import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:see_write_say/core/presentation/helpers/snackbar_helper.dart';
import 'package:see_write_say/features/story/api/story_api_service.dart';
import 'package:see_write_say/features/story/dto/chapter_dto.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';
import 'package:see_write_say/features/story/logic/audio_playback_service.dart';
import 'package:see_write_say/features/story/logic/paragraph_controller.dart';
import 'package:see_write_say/features/story/logic/recorder_controller.dart';
import 'package:see_write_say/features/story/logic/tts_controller.dart';

class StoryReadingProvider extends ChangeNotifier {
  final tts = TtsController();
  final audioService = AudioPlaybackService();
  final recorder = RecorderController();
  final paragraphController = ParagraphController();

  StoryDto? _story;
  bool _isLoading = false;
  String? _recordingPath;

  StoryDto? get story => _story;
  bool get isLoading => _isLoading;
  bool get isSpeaking => tts.state == TtsState.speaking;
  bool get isPaused => tts.state == TtsState.paused;
  bool get isRecording => recorder.isRecording;
  bool get isPlaying => audioService.isPlaying;
  bool get hasRecording => _recordingPath != null && File(_recordingPath!).existsSync();
  int get currentIndex => paragraphController.currentIndex;
  List<String> get paragraphs => paragraphController.paragraphs;
  int get paragraphCount => paragraphController.paragraphs.length;

  StoryReadingProvider() {
    tts.onStateChanged = (_) => notifyListeners();

    tts.onComplete = () async {
      if (!recorder.shouldBlockTts && paragraphController.hasNext) {
        paragraphController.next();
        debugPrint("▶️ 자동 다음 문단: index=$currentIndex");
        await tts.speak(paragraphs[currentIndex]);
      }
      notifyListeners();
    };

    audioService.setCallbacks(
      onChange: () => notifyListeners(),
      onComplete: () {
        recorder.onPlayStopped();
        notifyListeners();
      },
    );
  }

  void initialize({StoryDto? story, ChapterDto? chapter}) {
    if (story != null) {
      _story = story;
      paragraphController.initializeWithText(story.content);
      debugPrint("🟢 단편 초기화: storyId=${story.id}");
    } else if (chapter != null) {
      // 아직 내용을 직접 안 넣고, loadStory에서 chapterId로 fetch할 예정
      debugPrint("🟡 장편 초기화: chapterId=${chapter.id}");
    }
    notifyListeners();
  }

  void initializeWithStory(StoryDto story) {
    _story = story;
    paragraphController.initializeWithText(story.content);
    debugPrint("🆕 initializeWithStory: id=${story.id}, lang=${story.languageCode}");
    notifyListeners();
  }

  Future<void> loadStory({
    required BuildContext context,
    required int id,
    String lang = 'ko',
    bool autoSpeak = true,
    int? chapterId, // ✅ 추가
  }) async {
    await stopAll();
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await StoryApiService.fetchStoryDetail(
        id: id,
        lang: lang,
        chapterId: chapterId, // ✅ 추가
      );
      _story = fetched;
      paragraphController.initializeWithText(fetched.content);
      debugPrint("📥 Story loaded: id=${fetched.id}, lang=${fetched.languageCode}");

      if (autoSpeak && !recorder.shouldBlockTts) {
        Future.delayed(const Duration(milliseconds: 100), () => speakFromCurrent());
      }
    } catch (e) {
      debugPrint("❌ 스토리 로딩 실패: $e");
      SnackbarHelper.showError(context, e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> speakFromCurrent() async {
    if (paragraphs.isEmpty || recorder.shouldBlockTts) {
      debugPrint("📛 자동읽기 차단됨 (녹음 또는 재생 중)");
      return;
    }
    debugPrint("🔈 speakFromCurrent: index=$currentIndex");
    await tts.speak(paragraphs[currentIndex]);
    notifyListeners();
  }

  Future<void> pauseSpeaking() async {
    debugPrint("⏸ pauseSpeaking");
    await tts.pause();
    notifyListeners();
  }

  Future<void> resumeSpeaking() async {
    debugPrint("▶️ resumeSpeaking");
    await tts.resume();
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    debugPrint("⏹ stopSpeaking");
    await tts.stop();

    if (recorder.isRecording) {
      await recorder.stop();
      debugPrint("🎙 녹음 중지됨 (stopSpeaking)");
    }

    if (audioService.isPlaying) {
      await audioService.stop();
      recorder.onPlayStopped();
      debugPrint("▶️ 재생 중지됨 (stopSpeaking)");
    }

    paragraphController.initializeWithText(paragraphs.join('\n'));
    notifyListeners();
  }

  Future<void> stopAll() async {
    debugPrint("🛑 stopAll 호출됨");
    await tts.stop();
    await audioService.stop();
    await recorder.stopAll();
    notifyListeners();
  }

  Future<void> goToNextParagraph() async {
    if (!paragraphController.hasNext) return;
    paragraphController.next();
    debugPrint("➡️ goToNextParagraph: $currentIndex");
    await tts.stop();

    if (!recorder.shouldBlockTts) {
      Future.delayed(Duration(milliseconds: 100), () => speakFromCurrent());
    }

    notifyListeners();
  }

  Future<void> goToPreviousParagraph() async {
    if (!paragraphController.hasPrevious) return;
    paragraphController.previous();
    debugPrint("⬅️ goToPreviousParagraph: $currentIndex");
    await tts.stop();

    if (!recorder.shouldBlockTts) {
      Future.delayed(Duration(milliseconds: 100), () => speakFromCurrent());
    }

    notifyListeners();
  }

  Future<void> goToNextParagraphOrSeek() async {
    if (audioService.isPlaying) {
      await audioService.seekForward();
      return;
    }
    await goToNextParagraph();
  }

  Future<void> goToPreviousParagraphOrSeek() async {
    if (audioService.isPlaying) {
      await audioService.seekBackward();
      return;
    }
    await goToPreviousParagraph();
  }

  Future<String> _buildRecordingPath(int storyId, String lang) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$storyId/$lang');
    debugPrint("📁 녹음 경로 요청됨: ${folder.path}");
    if (!await folder.exists()) {
      try {
        await folder.create(recursive: true);
      } catch (e) {
        debugPrint("❌ 폴더 생성 실패: $e");
        rethrow;
      }
    }
    return '${folder.path}/recorded_audio.aac';
  }

  Future<void> toggleRecording(BuildContext context) async {
    if (_story == null) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      SnackbarHelper.show(context, "마이크 권한이 필요합니다.");
      return;
    }

    // ✅ 이미 녹음 중이라면 중지만 하고 리턴
    if (recorder.isRecording) {
      await stopAll(); // 이 안에 recorder.stop() 포함됨
      debugPrint("🎤 녹음 완료됨");
      SnackbarHelper.show(context, "녹음이 완료되었습니다.");
      notifyListeners();
      return;
    }

    // ✅ 녹음 시작
    try {
      await stopAll(); // 재생 중단 등 정리
      _recordingPath = await _buildRecordingPath(_story!.id, _story!.languageCode);
      await recorder.initializeWithPath(_recordingPath!);
      await recorder.start(_recordingPath!);
      debugPrint("🎙 녹음 시작됨: $_recordingPath");
      SnackbarHelper.show(context, "녹음을 시작합니다...");
    } catch (e) {
      debugPrint("❌ 녹음 실패: $e");
      SnackbarHelper.show(context, "녹음을 시작할 수 없습니다.");
    }

    notifyListeners();
  }

  Future<void> togglePlayRecording(BuildContext context) async {
    if (_story == null) return;

    final path = await _buildRecordingPath(_story!.id, _story!.languageCode);
    _recordingPath = path;
    debugPrint("🎵 재생 요청 경로: $path");

    final file = File(path);
    final exists = file.existsSync();
    debugPrint("📂 파일 존재 여부: $exists");
    if (!exists) {
      debugPrint("📛 재생 중단 - 녹음 파일 없음");
      SnackbarHelper.show(context, "녹음된 내용이 없습니다.");
      return;
    }

    if (audioService.isPlaying) {
      await audioService.stop();
      recorder.onPlayStopped();
      debugPrint("🛑 녹음 재생 중단");
      notifyListeners();
      return;
    }

    await stopAll();

    try {
      await audioService.play(path);
      recorder.onPlayStarted();
      debugPrint("▶️ 녹음 재생 시작: $path");
      SnackbarHelper.show(context, "녹음을 재생합니다.");
    } catch (e) {
      debugPrint("❌ 녹음 재생 실패: $e");
      SnackbarHelper.show(context, "녹음 재생에 실패했습니다.");
    }

    notifyListeners();
  }


  @override
  void dispose() {
    tts.dispose();
    recorder.dispose();
    audioService.dispose();
    super.dispose();
  }
}