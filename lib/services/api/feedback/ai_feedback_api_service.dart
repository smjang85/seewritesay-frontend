import 'dart:convert';
import 'dart:io';
import 'package:SeeWriteSay/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class AiFeedbackApiService {
  static Future<Map<String, String>> fetchAIWriteFeedback(
    String sentence,
    int imageId,
  ) async {
    final token = await CommonLogicService.getToken();

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

  static Future<Map<String, dynamic>> fetchAIReadingFeedback(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception("녹음 파일이 존재하지 않습니다.");
      }

      // ✅ 토큰 가져오기
      final token = await CommonLogicService.getToken();

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          filePath,
          filename: file.uri.pathSegments.last,
        ),
      });

      final response = await ApiClient.dio.post(
        ApiConstants.aiFeedbackGenerateReadingUrl,
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
          headers: {
            'Authorization': 'Bearer $token', // ✅ 토큰 추가
          },
        ),
      );

      debugPrint("response : $response");
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      } else if (response.statusCode == 401) {
        throw Exception("🔒 로그인 필요: 토큰이 없거나 만료됨");
      } else {
        throw Exception("서버 오류: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      throw Exception("❌ 발음 피드백 요청 실패: $e");
    }
  }
}
