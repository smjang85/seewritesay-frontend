import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../dto/story_dto.dart';
import 'package:see_write_say/app/constants/api_constants.dart';
import 'package:see_write_say/core/helpers/network/api_client.dart';

class StoryApiService {
  /// 공통 에러 핸들링
  static void _handleError(http.Response response) {
    final body = json.decode(response.body);
    final message = body['message'] ?? '에러가 발생했습니다.';
    debugPrint("❌ 에러 응답: ${response.statusCode}, body: ${response.body}");
    throw Exception(message);
  }

  /// 전체 스토리 목록 조회
  static Future<List<StoryDto>> fetchStories({String lang = 'ko'}) async {
    final url = Uri.parse('${ApiConstants.storyUrl}?lang=$lang');
    final headers = await ApiClient.buildHeaders();

    debugPrint("📥 fetchStories url: $url");

    final response = await http.get(url, headers: headers);
    debugPrint("📤 response: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded['data'];
      if (data == null) {
        debugPrint("✅ 데이터 없음 (null)");
        return [];
      }
      debugPrint("📚 data: $data");
      return (data as List<dynamic>)
          .map((json) => StoryDto.fromJson(json))
          .toList();
    } else if (response.statusCode == 204) {
      debugPrint("✅ 데이터 없음 (204)");
      return [];
    } else {
      _handleError(response);
      return []; // 안 올 일이지만 형식상
    }
  }

  /// 단일 스토리 상세 조회
  static Future<StoryDto> fetchStoryDetail({
    required int id,
    String lang = 'ko',
  }) async {
    final url = Uri.parse('${ApiConstants.storyUrl}/$id?lang=$lang');
    debugPrint("fetchStoryDetail url : $url");

    final headers = await ApiClient.buildHeaders();

    final response = await http.get(url, headers: headers);

    debugPrint("fetchStoryDetail response.statusCode : ${response.statusCode}");
    debugPrint("fetchStoryDetail response.body : ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded['data'];
      final result = StoryDto.fromJson(data);
      debugPrint("fetchStoryDetail result : $result");
      return result;
    } else {
      _handleError(response);
      throw Exception('스토리를 불러오는데 실패했습니다'); // fallback
    }
  }
}
