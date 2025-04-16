import 'dart:convert';
import 'dart:io';
import 'package:see_write_say/core/data/shared_prefs_service.dart';
import 'package:see_write_say/core/helpers/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import 'package:see_write_say/app/constants/api_constants.dart';

class ReadingApiService {
  static Future<Map<String, dynamic>> fetchAIReadingFeedback(
      String filePath,
      int imageId,
      String? sentence,
      ) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception("녹음 파일이 존재하지 않습니다.");
    }

    final token = await StorageService.getToken();

    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        filePath,
        filename: file.uri.pathSegments.last,
      ),
      "sentence": sentence,
      "imageId": imageId,
    });

    final response = await ApiClient.dio.post(
      ApiConstants.aiFeedbackGenerateReadingUrl,
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200 && response.data['data'] != null) {
      return response.data['data'];
    } else if (response.statusCode == 401) {
      throw Exception("🔒 로그인 필요: 토큰이 없거나 만료됨");
    } else {
      throw Exception("서버 오류: ${response.statusCode} - ${response.data}");
    }
  }



  static Future<void> decreaseReadingFeedbackCount(
      int imageId,
      ) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.userFeedbackReadingDecrementUrl),
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
