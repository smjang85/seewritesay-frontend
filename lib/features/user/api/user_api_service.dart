import 'dart:convert';
import 'package:see_write_say/core/data/shared_prefs_service.dart';
import 'package:see_write_say/features/user/dto/user_profile_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:see_write_say/app/constants/api_constants.dart';


class UserApiService {
  static Future<bool> checkNicknameAvailable(String nickname) async {
    final token = await StorageService.getToken(); // ✅ 토큰 불러오기

    final uri = Uri.parse(ApiConstants.userCheckNicknameUrl)
        .replace(queryParameters: {'nickname': nickname});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']['available'] == true; // ✅ ApiResponse 구조 반영
    } else {
      throw Exception('닉네임 중복 확인 실패: ${response.statusCode}');
    }
  }

  static Future<String> generateRandomNickname() async {
    final token = await StorageService.getToken(); // ✅ 토큰 필요 시 동일하게 적용

    final uri = Uri.parse(ApiConstants.userGenerateNicknameUrl);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']['nickname'] as String; // ✅ ApiResponse 구조 반영
    } else {
      throw Exception('랜덤 닉네임 생성 실패: ${response.statusCode}');
    }
  }

  static Future<void> updateProfile({
    required String nickname,
    required String avatar,
    required String ageGroup,
  }) async {
    final token = await StorageService.getToken(); // ✅ 토큰 불러오기

    final uri = Uri.parse(ApiConstants.userUpdateProfileUrl);
    final avatarFileName = avatar
        .split('/')
        .last;

    debugPrint("avatar : $avatar");

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nickname': nickname,
        'avatar': avatarFileName,
        'ageGroup': ageGroup,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception('프로필 업데이트 실패: ${response.statusCode} ${response.body}');
    }
  }

  static Future<UserProfileDto> getCurrentUserProfile() async {
    final token = await StorageService.getToken();

    final uri = Uri.parse(ApiConstants.userCurrentProfileUrl);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserProfileDto.fromJson(json['data']);
    } else {
      throw Exception('사용자 정보 조회 실패: ${response.statusCode}');
    }
  }
}