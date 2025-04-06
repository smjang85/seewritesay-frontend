import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/constants/api_constants.dart';

import '/model/img_info.dart';

class ImgService {
  // 서버에서 이미지 리스트 전체를 가져옴
  static Future<List<ImgInfo>> fetchAllImages() async {
    // 예시 구현
    final response = await http.get(Uri.parse(ApiConstants.imgList));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => ImgInfo.fromJson(e)).toList();
    } else {
      throw Exception('이미지 목록 불러오기 실패');
    }
  }
}
