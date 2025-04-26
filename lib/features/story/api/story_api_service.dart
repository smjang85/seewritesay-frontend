import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:see_write_say/app/constants/api_constants.dart';
import 'package:see_write_say/core/helpers/network/api_client.dart';
import 'package:see_write_say/features/story/dto/chapter_dto.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';

class StoryApiService {
  /// 공통 에러 핸들링
  static void _handleError(http.Response response) {
    final body = json.decode(response.body);
    final message = body['message'] ?? '에러가 발생했습니다.';
    debugPrint("❌ [Error] ${response.statusCode} - $message");
    throw Exception(message);
  }

  /// 전체 스토리 목록 조회
  static Future<List<StoryDto>> fetchStories({
    String lang = 'ko',
    String? type,
  }) async {
    final uri = Uri.parse(ApiConstants.storyUrl).replace(
      queryParameters: {
        'lang': lang,
        if (type != null) 'type': type,
      },
    );

    final headers = await ApiClient.buildHeaders();
    debugPrint("📥 [fetchStories] GET $uri");

    final response = await http.get(uri, headers: headers);
    debugPrint("📤 [fetchStories] Response: ${response.statusCode}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded['data'];

      debugPrint("📤 [fetchStories] data: ${data}");

      if (data == null) return [];
      return (data as List).map((json) => StoryDto.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      return [];
    } else {
      _handleError(response);
      return [];
    }
  }

  /// 단일 스토리 상세 조회 (단편/장편 공통)
  static Future<StoryDto> fetchStoryDetail({
    required int id,
    String lang = 'ko',
    int? chapterId, // 🔥 장편 대응
  }) async {
    final query = {
      'lang': lang,
      if (chapterId != null) 'chapterId': chapterId.toString(),
    };
    final url = Uri.parse('${ApiConstants.storyUrl}/$id')
        .replace(queryParameters: query);


    final headers = await ApiClient.buildHeaders();
    debugPrint("📥 fetchStoryDetail url: $url");

    final response = await http.get(url, headers: headers);
    debugPrint("📤 response: ${response.statusCode} / ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      return StoryDto.fromJson(data);
    } else {
      _handleError(response);
      throw Exception('스토리를 불러오는데 실패했습니다.');
    }
  }


  /// 장편: 스토리 ID에 해당하는 챕터 목록 조회
  static Future<List<ChapterDto>> fetchChapters(int storyId) async {
    final uri = Uri.parse('${ApiConstants.storyUrl}/$storyId/chapters');
    final headers = await ApiClient.buildHeaders();

    debugPrint("📥 [fetchChapters] GET $uri");

    final response = await http.get(uri, headers: headers);
    debugPrint("📤 [fetchChapters] Response: ${response.statusCode}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded['data'];
      debugPrint("📥 [fetchChapters] data $data");

      if (data == null) return [];
      return (data as List).map((e) => ChapterDto.fromJson(e)).toList();
    } else if (response.statusCode == 204) {
      return [];
    } else {
      _handleError(response);
      return [];
    }
  }
}
