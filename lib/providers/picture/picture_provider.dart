import 'package:SeeWriteSay/dto/image_dto.dart';
import 'package:flutter/material.dart';
import 'package:SeeWriteSay/services/api/image/image_api_service.dart';
import 'package:SeeWriteSay/services/logic/picture/picture_logic_service.dart';

class PictureProvider extends ChangeNotifier {
  List<ImageDto> _images = [];
  final Set<String> _usedImagePaths = {};
  ImageDto? _selectedImage;
  bool _imageLoadSuccess = true;

  List<String> _categories = ['전체'];
  String _selectedCategory = '전체';

  List<ImageDto> get images => _images;
  ImageDto? get selectedImage => _selectedImage;
  bool get imageLoadSuccess => _imageLoadSuccess;

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;

  bool get isAlreadyUsed =>
      _selectedImage != null && _usedImagePaths.contains(_selectedImage!.path);

  Future<void> fetchImages() async {
    try {
      _images = await ImageApiService.fetchAllImages();
      _extractCategories();
      loadNextImage();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ 이미지 불러오기 실패: $e");
      _imageLoadSuccess = false;
      notifyListeners();
    }
  }

  Future<void> loadUsedImages() async {
    final used = await PictureLogicService.loadUsedImagePaths();
    _usedImagePaths
      ..clear()
      ..addAll(used);
    notifyListeners();
  }

  void loadNextImage() {
    if (_images.isEmpty) return;

    final filteredImages = _selectedCategory == '전체'
        ? _images
        : _images.where((img) => img.categoryName == _selectedCategory).toList();

    if (filteredImages.isEmpty) {
      _selectedImage = null;
      _imageLoadSuccess = false;
      notifyListeners();
      return;
    }

    final currentIndex = _selectedImage == null
        ? -1
        : filteredImages.indexWhere((img) => img.id == _selectedImage!.id);

    final total = filteredImages.length;

    // 1. 히스토리가 없는 이미지 우선 선택
    for (int offset = 1; offset <= total; offset++) {
      final nextIndex = (currentIndex + offset) % total;
      final next = filteredImages[nextIndex];
      if (!_usedImagePaths.contains(next.path)) {
        _selectedImage = next;
        _imageLoadSuccess = true;
        notifyListeners();
        return;
      }
    }

    // 2. 모두 히스토리가 있을 경우 순차적으로
    _selectedImage = filteredImages[(currentIndex + 1) % total];
    _imageLoadSuccess = true;
    notifyListeners();
  }

  void setImageLoadSuccess(bool success) {
    if (_imageLoadSuccess != success) {
      _imageLoadSuccess = success;
      notifyListeners();
    }
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadNextImage();
      notifyListeners();
    }
  }

  void _extractCategories() {
    final categorySet = <String>{'전체'};

    for (var image in _images) {
      final category = image.categoryName;
      if (category != null && category.isNotEmpty) {
        categorySet.add(category);
      }
    }
    _categories = categorySet.toList();
  }

  Future<void> fetchCategoriesFromHistory(List<String> serverCategories) async {
    _categories = ['전체', ...serverCategories.toSet()].toList();
    notifyListeners();
  }
}
