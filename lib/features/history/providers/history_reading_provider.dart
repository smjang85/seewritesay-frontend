import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:see_write_say/core/services/audio/audio_service.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';

class HistoryReadingProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();

  Map<String, List<String>> groupedRecordings = {}; // key: image.name
  Map<int, ImageDto> imageDtoMap = {}; // key: image.id
  String selectedImageGroup = '';
  List<String> _allRecordings = [];
  List<ImageDto> _allImages = [];

  List<String> categories = ['전체'];
  String selectedCategory = '전체';

  Duration get position => _audioService.position;
  Duration get duration => _audioService.duration;
  String? get currentFile => _audioService.currentFile;

  bool isPlayingFile(String file) => _audioService.isPlayingFile(file);
  bool isPausedFile(String file) => _audioService.isPausedFile(file);

  Future<void> initializeHistoryView(List<ImageDto> imageList) async {
    _audioService.setCallbacks(
      onChange: notifyListeners,
      onComplete: () {
        // 완료 시 UI 리프레시
        notifyListeners();
      },
    );

    _allImages = imageList;

    final dir = await getApplicationDocumentsDirectory();
    _allRecordings = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.path.split('/').last)
        .where((name) => name.endsWith('.aac'))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    _extractCategories();
    _filterByCategory();

    _audioService.setCallbacks(
      onChange: () => notifyListeners(),
      onComplete: () => notifyListeners(),
    );

    notifyListeners();
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

  void _extractCategories() {
    final Set<String> categorySet = {'전체'};

    for (final file in _allRecordings) {
      final parts = file.split('_');
      if (parts.length < 3) continue;
      final imageId = int.tryParse(parts[0]);
      final image = _allImages.firstWhere(
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
    final filtered = _allImages.where((img) => selectedCategory == '전체' || img.category == selectedCategory).toList();
    _buildGroupedRecordings(filtered);
  }

  void _buildGroupedRecordings(List<ImageDto> images) {
    final Map<String, List<String>> newGrouped = {};
    final Map<int, ImageDto> newImageMap = {};

    for (final image in images) {
      final matches = _allRecordings.where((file) => file.startsWith('${image.id}_')).toList();
      if (matches.isNotEmpty) {
        newGrouped[image.name] = matches;
        newImageMap[image.id] = image;
      }
    }

    groupedRecordings = newGrouped;
    imageDtoMap = newImageMap;
    selectedImageGroup = groupedRecordings.isNotEmpty ? groupedRecordings.keys.first : '';
  }

  ImageDto? get selectedImageDto {
    final image = _allImages.firstWhere(
          (img) => img.name == selectedImageGroup,
      orElse: () => ImageDto(id: 0, name: '', path: '', description: ''),
    );
    return image.id != 0 ? image : null;
  }

  Future<void> playRecording(String file) async {
    final dir = await getApplicationDocumentsDirectory();
    final fullPath = '${dir.path}/$file';
    await _audioService.togglePlayback(file, fullPath);
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    await _audioService.stop();
    notifyListeners();
  }

  Future<void> seekTo(Duration pos) async {
    await _audioService.seekTo(pos);
  }

  Future<void> deleteHistoryItem(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) await file.delete();

    groupedRecordings[selectedImageGroup]?.remove(fileName);
    if ((groupedRecordings[selectedImageGroup]?.isEmpty ?? true)) {
      groupedRecordings.remove(selectedImageGroup);
      selectedImageGroup = groupedRecordings.isNotEmpty ? groupedRecordings.keys.first : '';
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
