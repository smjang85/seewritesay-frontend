import 'package:see_write_say/core/data/shared_prefs_service.dart';
import 'package:see_write_say/features/history/dto/history_writing_dto.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:see_write_say/app/constants/api_constants.dart';


class HistoryWritingApiService {
  /// 히스토리 목록 불러오기
  static Future<List<Map<String, dynamic>>> fetchHistory({int? imageId}) async {
    debugPrint("fetchHistory imageId : $imageId");
    final token = await StorageService.getToken();

    final uri = Uri.parse(ApiConstants.historyWritingUrl).replace(
      queryParameters: imageId != null ? {'imageId': imageId.toString()} : null,
    );

    debugPrint('📡 호출 URI: $uri');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      debugPrint("✅ json: $json");

      final List<dynamic> dataList = json['data'] ?? [];
      return dataList.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('❌ 히스토리 불러오기 실패: ${response.statusCode}');
    }
  }


  static Future<List<HistoryWritingDto>> fetchHistoryWithCategory() async {
    final token = await StorageService.getToken(); // ✅ 토큰 추가
    final url = ApiConstants.historyWritingWithCategoryUrl;

    debugPrint('📡 호출 URL (withCategory): $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      debugPrint("fetchHistoryWithCategory 응답 바디: ${response.body}");

      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data']; // 'data' 키 안의 리스트 추출

      return data.map((json) => HistoryWritingDto.fromJson(json)).toList();
    } else {
      debugPrint("❌ 응답 코드: ${response.statusCode}");
      debugPrint("❌ 응답 바디: ${response.body}");
      throw Exception('히스토리 불러오기 실패');
    }
  }

  /// 히스토리 저장하기
  static Future<void> saveHistory({
    required int imageId,
    required String sentence,
    required String grade,
  }) async {
    final token = await StorageService.getToken();

    debugPrint('saveHistory imageId $imageId');
    debugPrint('saveHistory sentence $sentence');
    debugPrint('saveHistory grade $grade');

    final body = jsonEncode({
      'imageId': imageId,
      'sentence': sentence,
      'grade': grade,
    });


    final res = await http.post(
      Uri.parse(ApiConstants.historyWritingUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    debugPrint("saveHistory :${res.statusCode}");
    if (res.statusCode != 204) {
      throw Exception('❌ 히스토리 저장 실패: ${res.statusCode}');
    }
  }

  static Future<void> deleteHistoryById(int id) async {
    final token = await StorageService.getToken();
    final uri = Uri.parse(ApiConstants.historyWritingDeleteUrl).replace(queryParameters: {'id': '$id'});

    final res = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode != 204) {
      throw Exception('❌ 히스토리 삭제 실패: ${res.statusCode}');
    }
  }
}
