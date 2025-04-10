import 'package:flutter/material.dart';
import 'package:SeeWriteSay/models/image_model.dart';

class ImageListProvider extends ChangeNotifier {
  List<ImageModel> _images = [];

  List<ImageModel> get images => _images;

  void setImages(List<ImageModel> newList) {
    _images = newList;
    notifyListeners();
  }

  ImageModel? findById(int id) {
    return _images.firstWhere((img) => img.id == id, orElse: () => ImageModel(id: -1, name: '', path: '', description: ''));
  }
}