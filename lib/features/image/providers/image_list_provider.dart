import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:flutter/material.dart';

class ImageListProvider extends ChangeNotifier {
  List<ImageDto> _images = [];

  List<ImageDto> get images => _images;

  void setImages(List<ImageDto> newList) {
    _images = newList;
    notifyListeners();
  }

  ImageDto? findById(int id) {
    return _images.firstWhere((img) => img.id == id, orElse: () => ImageDto(id: -1, name: '', path: '', description: ''));
  }
}