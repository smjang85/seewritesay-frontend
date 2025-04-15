import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class AuthApiService {

  // JWT 토큰 연장 API
  static Future<String?> refreshToken() async {
    try {
      final token = await CommonLogicService.getToken();

      final response = await http.post(
        Uri.parse(ApiConstants.authRefreshUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final raw = response.body.trim();

        // case 1: plain text ("Bearer ...")
        if (raw.startsWith("Bearer ")) {
          final newToken = raw.substring(7);
          await CommonLogicService.savePreference('jwt_token', newToken);
          debugPrint("🔐 새 토큰 저장 완료 (plain text): $newToken");
          return newToken;
        }

        // case 2: JSON response with "message" or "accessToken"
        final Map<String, dynamic> body = jsonDecode(raw);
        final message = body['message'] ?? body['accessToken'] ?? '';
        final newToken = message.startsWith("Bearer ") ? message.substring(7) : message;
        await CommonLogicService.savePreference('jwt_token', newToken);
        debugPrint("🔐 새 토큰 저장 완료 (JSON): $newToken");
        return newToken;
      } else if (response.statusCode == 401) {
        throw Exception("🔒 로그인 필요: 토큰 만료");
      } else {
        throw Exception("❌ 토큰 갱신 실패: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error in refreshToken: $e");
      throw Exception("토큰 갱신 중 오류 발생");
    }
  }

}
