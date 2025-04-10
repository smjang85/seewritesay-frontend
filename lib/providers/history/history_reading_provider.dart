import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class HistoryReadingProvider extends ChangeNotifier {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;

  Map<String, List<String>> _groupedRecordings = {};
  Map<String, ImageModel> _imageModelMap = {};
  String _selectedImageGroup = '';

  Map<String, List<String>> get groupedRecordings => _groupedRecordings;

  Map<String, ImageModel> get imageModelMap => _imageModelMap;

  String get selectedImageGroup => _selectedImageGroup;

  bool get isPlaying => _isPlaying;

  List<ImageModel> _allImages = [];
  List<String> _categories = ['전체'];
  String _selectedCategory = '전체';

  List<String> get categories => _categories;

  String get selectedCategory => _selectedCategory;

  List<String> _allRecordings = [];

  void setSelectedImageGroup(String value) {
    _selectedImageGroup = value;
    notifyListeners();
  }

  Future<void> initializeHistoryView(List<ImageModel> imageList) async {
    _allImages = imageList;
    debugPrint('✅ 이미지 개수: ${imageList.length}');

    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().whereType<File>().toList();
    _allRecordings =
        files
            .map((f) => f.path.split('/').last)
            .where((name) => name.endsWith('.aac'))
            .toList();

    debugPrint('✅ 녹음 파일 목록: $_allRecordings');

    _extractCategories(imageList);
    _filterByCategory();
  }

  Future<void> deleteHistoryItem(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fullPath = '\${dir.path}/\$fileName';
      final file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
        _groupedRecordings[_selectedImageGroup]?.remove(fileName);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ 파일 삭제 오류: \$e');
    }
  }

  Future<void> playRecording(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fullPath = '\${dir.path}/\$fileName';
      if (_player.isPlaying) {
        await _player.stopPlayer();
        _isPlaying = false;
      } else {
        await _player.startPlayer(
          fromURI: fullPath,
          whenFinished: () {
            _isPlaying = false;
            notifyListeners();
          },
        );
        _isPlaying = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 재생 오류: \$e');
    }
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _filterByCategory();
      notifyListeners();
    }
  }

  void _filterByCategory() {
    final filteredImages =
        _allImages
            .where(
              (img) =>
                  _selectedCategory == '전체' ||
                  (img.category != null && img.category == _selectedCategory),
            )
            .toList();
    _buildGroupedRecordings(filteredImages);
  }

  void _extractCategories(List<ImageModel> images) {
    final Set<String> categorySet = {'전체'};

    for (var fileName in _allRecordings) {
      final parts = fileName.split('_');
      if (parts.length < 3) continue;

      final imageIdStr = parts[0];
      final imageId = int.tryParse(imageIdStr);
      final image = images.firstWhere(
        (img) => img.id == imageId,
        orElse: () {
          debugPrint('❌ 매칭 실패 imageId: $imageId');
          return ImageModel(id: 0, name: '', path: '', description: '');
        },
      );

      if (image.id != 0 &&
          image.category != null &&
          image.category!.isNotEmpty) {
        categorySet.add(image.category!);
        debugPrint('📦 카테고리 추가됨: ${image.category!}');
      }
    }

    _categories = categorySet.toList();
    debugPrint('✅ 최종 카테고리 목록: $_categories');
  }

  void _buildGroupedRecordings(List<ImageModel> images) {
    final Map<String, List<String>> newGrouped = {};
    final Map<String, ImageModel> newMap = {};

    for (var image in images) {
      final imageIdStr = image.id.toString();
      final imageName = image.name;

      final matchingFiles =
          _allRecordings.where((file) {
            final parts = file.split('_');
            if (parts.length < 3) return false;
            final result = parts[0] == imageIdStr;
            debugPrint('🧩 매칭 체크: file=$file, imageId=$imageIdStr → $result');
            return result;
          }).toList();

      if (matchingFiles.isNotEmpty) {
        newGrouped[imageName] = matchingFiles;
        newMap[imageName] = image;
        debugPrint('✅ $imageName 에 녹음 ${matchingFiles.length}개');
      }
    }

    _groupedRecordings = newGrouped;
    _imageModelMap = newMap;

    if (_groupedRecordings.isNotEmpty) {
      _selectedImageGroup = _groupedRecordings.keys.first;
    } else {
      _selectedImageGroup = '';
      debugPrint('⚠️ groupedRecordings 비어있음');
    }
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }
}
