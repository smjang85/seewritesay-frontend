import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class AiFeedbackApiService {

  static Future<Map<String, String>> fetchAIFeedback(String sentence, int imageId) async {
    final token = await CommonLogicService.getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.aiFeedbackGenerateUrl),
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
        'grade': data['grade'] ?? 'F'
      };
    } else {
      throw Exception(response.body);

    }
  }


}
