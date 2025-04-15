import 'dart:convert';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserFeedbackApiService {
  // 남은 피드백 횟수 조회
  static Future<int> fetchRemainingCount(int imageId) async {
    final token = await CommonLogicService.getToken();
    if (token == null) throw Exception("❌ JWT 토큰 없음");

    debugPrint("imageId : $imageId");
    final response = await http.get(
      Uri.parse('${ApiConstants.userFeedbackUrl}?imageId=$imageId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      debugPrint("✅ json: $json");

      final int writingRemainingCount = json['data']['writingRemainingCount'];

      return writingRemainingCount;
    } else {
      throw Exception("❌ 피드백 횟수 조회 실패: ${response.statusCode} ${response.body}");
    }
  }

  // 피드백 1회 사용 (감소)
  static Future<void> decreaseFeedbackCount(int imageId) async {
    final token = await CommonLogicService.getToken();
    if (token == null) throw Exception("❌ JWT 토큰 없음");

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
