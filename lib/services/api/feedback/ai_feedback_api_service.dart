import 'dart:convert';
import 'dart:io';
import 'package:SeeWriteSay/utils/api_client.dart';
import 'package:SeeWriteSay/utils/dialog_popup_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class AiFeedbackApiService {
  static Future<Map<String, String>> fetchAIWriteFeedback(
      BuildContext context,
      String sentence,
      int imageId,
      ) async {
    final token = await CommonLogicService.getToken();

    DialogPopupHelper.showLoadingDialog(context);

    try {
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
    } finally {
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
    }
  }

  static Future<Map<String, dynamic>> fetchAIReadingFeedback(
      BuildContext context,
      String filePath,
      int imageId,
      String? sentence,
      ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception("녹음 파일이 존재하지 않습니다.");
      }

      final token = await CommonLogicService.getToken();

      DialogPopupHelper.showLoadingDialog(context);

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          filePath,
          filename: file.uri.pathSegments.last,
        ),
        "sentence": sentence,
        "imageId": imageId
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
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
