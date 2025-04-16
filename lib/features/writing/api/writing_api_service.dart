import 'dart:convert';
import 'package:see_write_say/core/data/shared_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:see_write_say/app/constants/api_constants.dart';

class WritingApiService {
  static Future<({int readingRemainingCount, int writingRemainingCount})> fetchRemainingCounts(
      int imageId,
      ) async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConstants.userFeedbackUrl}?imageId=$imageId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final data = json['data'] as Map<String, dynamic>;

      return (
      readingRemainingCount: (data['readingRemainingCount'] ?? 0) as int,
      writingRemainingCount: (data['writingRemainingCount'] ?? 0) as int,
      );
    } else {
      throw Exception("❌ 피드백 횟수 조회 실패: ${response.statusCode} ${response.body}");
    }
  }

  static Future<Map<String, String>> fetchAIWriteFeedback(
      String sentence,
      int imageId,
      ) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.aiFeedbackGenerateWritingUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'sentence': sentence, 'imageId': imageId}),
    );

    if (response.statusCode == 401) throw Exception("🔒 로그인 필요: 토큰이 없거나 만료됨");

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final data = json['data'];
      debugPrint("fetchAIFeedback data : $data");
      return {
        'correction': data['correction'] ?? sentence,
        'feedback': data['feedback'] ?? '',
        'grade': data['grade'] ?? 'F',
      };
    } else {
      throw Exception(response.body);
    }
  }

  static Future<void> decreaseWritingFeedbackCount(
      int imageId,
      ) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.userFeedbackWritingDecrementUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'imageId': imageId}),
    );

    if (response.statusCode != 204) {
      throw Exception("❌ 피드백 감소 실패: ${response.statusCode} ${response.body}");
    }
  }
}