import 'package:flutter/material.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/services/api/image/image_api_service.dart';
import 'package:SeeWriteSay/services/logic/picture/picture_logic_service.dart';

class PictureProvider extends ChangeNotifier {
  List<ImageModel> _images = [];
  final Set<String> _usedImagePaths = {};
  ImageModel? _selectedImage;
  bool _imageLoadSuccess = true;

  List<ImageModel> get images => _images;
  ImageModel? get selectedImage => _selectedImage;
  bool get imageLoadSuccess => _imageLoadSuccess;

  bool get isAlreadyUsed =>
      _selectedImage != null && _usedImagePaths.contains(_selectedImage!.path);

  Future<void> fetchImages() async {
    try {
      final images = await ImageApiService.fetchAllImages();
      _images = images;
      loadRandomImage();
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

  void loadRandomImage() {
    try {
      final image = PictureLogicService.pickRandomImage(_images, _usedImagePaths);
      _selectedImage = image;
      _imageLoadSuccess = true;
      notifyListeners();
    } catch (_) {
      _selectedImage = null;
      notifyListeners();
    }
  }

  void setImageLoadSuccess(bool success) {
    _imageLoadSuccess = success;
    notifyListeners();
  }
}
