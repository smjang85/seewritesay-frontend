import 'package:flutter/material.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/services/api/image/image_api_service.dart';
import 'package:SeeWriteSay/services/logic/picture/picture_logic_service.dart';

class PictureProvider extends ChangeNotifier {
  List<ImageModel> _images = [];
  final Set<String> _usedImagePaths = {};
  ImageModel? _selectedImage;
  bool _imageLoadSuccess = true;

  List<String> _categories = ['전체'];
  String _selectedCategory = '전체';

  List<ImageModel> get images => _images;
  ImageModel? get selectedImage => _selectedImage;
  bool get imageLoadSuccess => _imageLoadSuccess;

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;

  bool get isAlreadyUsed =>
      _selectedImage != null && _usedImagePaths.contains(_selectedImage!.path);

  Future<void> fetchImages() async {
    try {
      final images = await ImageApiService.fetchAllImages();
      _images = images;
      _extractCategories();
      loadNextImage();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ 이미지 불러오기 실패: $e");
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

    if (_selectedImage == null || !filteredImages.contains(_selectedImage)) {
      _selectedImage = filteredImages.first;
      _imageLoadSuccess = true;
      notifyListeners();
      return;
    }

    final total = filteredImages.length;
    final currentIndex = filteredImages.indexWhere((img) => img.id == _selectedImage!.id);

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
    final fallbackIndex = (currentIndex + 1) % total;
    _selectedImage = filteredImages[fallbackIndex];
    _imageLoadSuccess = true;
    notifyListeners();
  }

  void setImageLoadSuccess(bool success) {
    _imageLoadSuccess = success;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadNextImage();
      notifyListeners();
    }
  }

  void _extractCategories() {
    final categorySet = {'전체'};
    for (var image in _images) {
      if (image.categoryName != null && image.categoryName!.isNotEmpty) {
        categorySet.add(image.categoryName!);
      }
    }
    _categories = categorySet.toList();
  }

  Future<void> fetchCategoriesFromHistory(List<String> serverCategories) async {
    final categorySet = {'전체', ...serverCategories};
    _categories = categorySet.toList();
    notifyListeners();
  }
}
