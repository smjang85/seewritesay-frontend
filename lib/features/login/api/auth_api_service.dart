import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:see_write_say/app/constants/api_constants.dart';
import 'package:see_write_say/core/data/shared_prefs_service.dart';

class AuthApiService {
  /// JWT 토큰을 갱신합니다.
  static Future<String?> refreshToken() async {
    try {
      final token = await StorageService.getToken();

      final response = await http.post(
        Uri.parse(ApiConstants.authRefreshUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final raw = response.body.trim();
      debugPrint("📥 [토큰 갱신 응답] status: ${response.statusCode}");
      debugPrint("📥 [토큰 갱신 응답] body: $raw");

      if (response.statusCode == 200) {
        // case 1: 단순 텍스트 형식
        if (raw.startsWith("Bearer ")) {
          final newToken = raw.substring(7);
          await StorageService.save('jwt_token', newToken);
          debugPrint("🔐 새 토큰 저장 완료 (텍스트): $newToken");
          return newToken;
        }

        // case 2: JSON 형식
        try {
          final Map<String, dynamic> body = jsonDecode(raw);
          final token = body['accessToken'] ?? body['token'] ?? body['message'];
          if (token is String && token.isNotEmpty) {
            final newToken = token.startsWith("Bearer ") ? token.substring(7) : token;
            await StorageService.save('jwt_token', newToken);
            debugPrint("🔐 새 토큰 저장 완료 (JSON): $newToken");
            return newToken;
          } else {
            throw Exception("응답에 유효한 토큰이 없습니다.");
          }
        } catch (e) {
          throw Exception("JSON 파싱 오류: $e");
        }
      } else if (response.statusCode == 401) {
        throw Exception("🔒 로그인 필요: 토큰이 만료되었습니다.");
      } else {
        throw Exception("❌ 토큰 갱신 실패: ${response.statusCode} - $raw");
      }
    } catch (e) {
      debugPrint("❗ [토큰 갱신 오류] $e");
      throw Exception("토큰 갱신 중 오류가 발생했습니다.");
    }
  }

  /// 구글 ID 토큰으로 로그인 요청을 보내고 JWT를 반환합니다.
  static Future<String> loginWithGoogleIdToken(String? idToken) async {
    if (idToken == null || idToken.isEmpty) {
      debugPrint("❌ [로그인 오류] idToken이 null 또는 비어 있음");
      throw Exception("구글 로그인 토큰이 없습니다.");
    }

    final url = Uri.parse(ApiConstants.googleLoginUrl);
    debugPrint("📡 [Google 로그인 요청] URL: $url");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    final raw = response.body.trim();
    debugPrint("📥 [서버 응답] status: ${response.statusCode}");
    debugPrint("📥 [서버 응답] body: $raw");

    if (response.statusCode == 200) {
      try {
        if (raw.startsWith("Bearer ")) {
          return raw.substring(7);
        }

        final json = jsonDecode(raw);
        final token = json['token'] ?? json['accessToken'] ?? json['message'];
        if (token is String && token.isNotEmpty) {
          return token.startsWith("Bearer ") ? token.substring(7) : token;
        } else {
          throw Exception("서버 응답에 유효한 토큰이 없습니다.");
        }
      } catch (e) {
        throw Exception("로그인 응답 파싱 실패: $e");
      }
    } else {
      throw Exception("로그인 실패: ${response.statusCode} - $raw");
    }
  }
}
