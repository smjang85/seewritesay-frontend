import 'dart:convert';
import 'package:SeeWriteSay/dto/image_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/constants/api_constants.dart';

class ImageApiService {
  // 서버에서 이미지 리스트 전체를 가져옴
  static Future<List<ImageDto>> fetchAllImages() async {
    final response = await http.get(Uri.parse(ApiConstants.imagesUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data']; // 'data' 키 안의 리스트 추출
      debugPrint("fetchAllImages data : $data");
      return data.map((e) => ImageDto.fromJson(e)).toList();
    } else {
      throw Exception('이미지 목록 불러오기 실패');
    }
  }

  static Future<List<String>> fetchCategories() async {
    final response = await http.get(Uri.parse(ApiConstants.imagesCategoriesUrl));
    debugPrint("fetchCategories response: $response");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
