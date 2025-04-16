import 'dart:async';
import 'dart:io';
import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class HistoryReadingProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, List<String>> groupedRecordings = {};
  Map<String, ImageDto> imageDtoMap = {};
  String selectedImageGroup = '';
  List<String> _allRecordings = [];

  List<ImageDto> _allImages = [];
  List<String> categories = ['전체'];
  String selectedCategory = '전체';

  String? _currentFile;
  bool _isPlaying = false;
  bool _isPaused = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;

  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  String? get currentFile => _currentFile;

  StreamSubscription<Duration>? _positionSubscription;

  bool isPlayingFile(String fileName) {
    return _isPlaying && !_isPaused && _currentFile == fileName;
  }

  bool isPausedFile(String fileName) {
    return _isPaused && _currentFile == fileName;
  }

  Future<void> initializeHistoryView(List<ImageDto> imageList) async {
    _allImages = imageList;

    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().whereType<File>().toList();
    _allRecordings = files
        .map((f) => f.path.split('/').last)
        .where((name) => name.endsWith('.aac'))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    _extractCategories(imageList);
    _filterByCategory();
  }

  void setSelectedImageGroup(String value) {
    selectedImageGroup = value;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    selectedCategory = category;
    _filterByCategory();
    notifyListeners();
  }

  void _extractCategories(List<ImageDto> images) {
    final Set<String> categorySet = {'전체'};

    for (var fileName in _allRecordings) {
      final parts = fileName.split('_');
      if (parts.length < 3) continue;

      final imageIdStr = parts[0];
      final imageId = int.tryParse(imageIdStr);
      final image = images.firstWhere(
            (img) => img.id == imageId,
        orElse: () => ImageDto(id: 0, name: '', path: '', description: ''),
      );

      if (image.id != 0 && image.category?.isNotEmpty == true) {
        categorySet.add(image.category!);
      }
    }

    categories = categorySet.toList();
  }

  void _filterByCategory() {
    final filteredImages = _allImages.where((img) {
      return selectedCategory == '전체' || img.category == selectedCategory;
    }).toList();

    _buildGroupedRecordings(filteredImages);
  }

  void _buildGroupedRecordings(List<ImageDto> images) {
    final Map<String, List<String>> newGrouped = {};
    final Map<String, ImageDto> newMap = {};

    for (var image in images) {
      final imageIdStr = image.id.toString();
      final imageName = image.name;

      final matchingFiles = _allRecordings.where((file) {
        final parts = file.split('_');
        return parts.length >= 3 && parts[0] == imageIdStr;
      }).toList();

      if (matchingFiles.isNotEmpty) {
        newGrouped[imageName] = matchingFiles;
        newMap[imageName] = image;
      }
    }

    groupedRecordings = newGrouped;
    imageDtoMap = newMap;

    if (groupedRecordings.isNotEmpty) {
      selectedImageGroup = groupedRecordings.keys.first;
    } else {
      selectedImageGroup = '';
    }
  }

  Future<void> playRecording(String fileName) async {
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      notifyListeners();
    });

    final dir = await getApplicationDocumentsDirectory();
    final fullPath = '${dir.path}/$fileName';

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

    await _audioPlayer.setFilePath(fullPath);
    _currentFile = fileName;
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();

    await _audioPlayer.play();

    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _isPaused = false;
        _currentFile = null;
        notifyListeners();
      }
    });
  }

  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero); // 프로그레스바 맨 앞으로 이동

    _isPlaying = false;
    _isPaused = false;
    _currentFile = null;

    notifyListeners(); // UI 업데이트
  }


  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> deleteHistoryItem(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final fullPath = '${dir.path}/$fileName';
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }

    groupedRecordings[selectedImageGroup]?.remove(fileName);
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
