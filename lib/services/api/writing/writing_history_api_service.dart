import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';

class WritingHistoryApiService {
  /// 히스토리 목록 불러오기
  static Future<List<Map<String, dynamic>>> fetchHistory({int? imageId}) async {
    final token = await CommonLogicService.getToken();

    final uri = Uri.parse(ApiConstants.writingHistoryUrl).replace(
      queryParameters: imageId != null ? {'imageId': imageId.toString()} : null,
    );

    debugPrint('📡 호출 URI: $uri');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      final List<dynamic> list = json.decode(res.body);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('❌ 히스토리 불러오기 실패: ${res.statusCode}');
    }
  }

  /// 히스토리 저장하기
  static Future<void> saveHistory({
    required int imageId,
    required String sentence,
  }) async {
    final token = await CommonLogicService.getToken();

    debugPrint('saveHistory imageId $imageId');
    debugPrint('saveHistory sentence $sentence');

    final body = jsonEncode({
      'imageId': imageId,
      'sentence': sentence,
    });


    final res = await http.post(
      Uri.parse(ApiConstants.writingHistoryUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception('❌ 히스토리 저장 실패: ${res.statusCode}');
    }
  }
}
