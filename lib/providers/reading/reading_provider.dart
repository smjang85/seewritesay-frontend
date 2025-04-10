import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:SeeWriteSay/models/image_model.dart';

class ReadingProvider extends ChangeNotifier {
  String sentence = '';
  ImageModel? imageModel;

  String inputText = '';
  String feedback = '';
  double accuracy = 0.0;
  bool showResult = false;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String currentFilePath = '';
  List<String> recordedPaths = [];
  Map<String, List<String>> groupedRecordings = {};

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  final FlutterTts _flutterTts = FlutterTts();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  StreamSubscription? _playerSubscription;

  Future<void> initialize(String sentence, {ImageModel? imageModel}) async {
    debugPrint("🟡 ReadingProvider.initialize 호출됨");
    debugPrint("📌 sentence: $sentence");
    debugPrint("📌 imageModel: $imageModel");

    this.sentence = sentence;
    this.imageModel = imageModel;

    await _recorder.openRecorder();
    await _player.openPlayer();

    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(".aac"))
        .toList();

    debugPrint("📂 찾은 녹음 파일 개수: ${files.length}");
    for (final f in files) {
      debugPrint("📄 파일 경로: ${f.path}");
    }

    recordedPaths = files
        .map((f) => f.path.split('/').last.replaceAll('.aac', ''))
        .toList();

    groupedRecordings = groupBy(recordedPaths, (String fileName) {
      final parts = fileName.split('_');
      debugPrint("📌 그룹핑용 분할: $parts");
      return parts.length > 1 ? parts[1] : 'unknown'; // imageName 기준
    });

    for (final entry in groupedRecordings.entries) {
      debugPrint("🗂 그룹: ${entry.key} -> ${entry.value.length}개 파일");
      entry.value.sort((a, b) {
        final aTime = a.split('_').last;
        final bTime = b.split('_').last;
        return bTime.compareTo(aTime);
      });
    }

    notifyListeners();
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _isRecording = true;
    notifyListeners();

    final dir = await getApplicationDocumentsDirectory();
    final imageId = imageModel?.id ?? 'unknown';
    final imageName = imageModel?.name.split('.').first ?? 'unknown';
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = '${imageId}_${imageName}_$dateStr';
    currentFilePath = '${dir.path}/$fileName.aac';

    await _recorder.startRecorder(toFile: currentFilePath);
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    _isRecording = false;

    final fileName = currentFilePath.split('/').last.replaceAll('.aac', '');
    _updateHistory(fileName);

    showResult = true;
    notifyListeners();
  }

  void evaluateRecording(String inputText) {
    this.inputText = inputText;
    final similarity = sentence.similarityTo(inputText);
    accuracy = similarity;

    if (similarity > 0.8) {
      feedback = '잘 읽었어요!';
    } else if (similarity > 0.5) {
      feedback = '조금 더 정확히 읽어보세요.';
    } else {
      feedback = '다시 한 번 도전해볼까요?';
    }

    notifyListeners();
  }

  Future<void> playRecording(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final fullPath = fileName.startsWith(dir.path) ? fileName : '${dir.path}/$fileName';

    if (_isPlaying) {
      await _player.stopPlayer();
      _isPlaying = false;
      notifyListeners();
      return;
    }

    await _player.startPlayer(
      fromURI: fullPath,
      whenFinished: () {
        _isPlaying = false;
        position = Duration.zero;
        notifyListeners();
      },
    );

    _isPlaying = true;
    _playerSubscription = _player.onProgress?.listen((event) {
      position = event.position;
      duration = event.duration;
      notifyListeners();
    });
  }

  void seekTo(double value) {
    final seekPosition = Duration(
      milliseconds: (duration.inMilliseconds * value).toInt(),
    );
    _player.seekToPlayer(seekPosition);
  }

  void _updateHistory(String fileName) async {
    if (fileName.isEmpty) return;

    final imageName = fileName.split('_')[1];
    groupedRecordings.putIfAbsent(imageName, () => []);
    groupedRecordings[imageName]!.remove(fileName);
    groupedRecordings[imageName]!.insert(0, fileName);

    final allFiles = groupedRecordings.values.expand((list) => list).toList();
    recordedPaths = allFiles;

    if (groupedRecordings[imageName]!.length > 5) {
      final removed = groupedRecordings[imageName]!.removeLast();
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$removed.aac';
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }

    notifyListeners();
  }

  Future<void> deleteHistoryItem(String fileName) async {
    final imageName = fileName.split('_')[1];
    groupedRecordings[imageName]?.remove(fileName);
    if (groupedRecordings[imageName]?.isEmpty ?? true) {
      groupedRecordings.remove(imageName);
    }

    recordedPaths = groupedRecordings.values.expand((list) => list).toList();
    notifyListeners();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.aac');
    if (await file.exists()) {
      await file.delete();
    }
  }

  void disposeResources() {
    _flutterTts.stop();
    _recorder.stopRecorder();
    _player.stopPlayer();
    _playerSubscription?.cancel();
  }

  @override
  void dispose() {
    disposeResources();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }
}