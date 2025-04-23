import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:see_write_say/core/data/shared_prefs_service.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://your-api-domain.com/api/v1', // 여기에 base URL 지정
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (object) {
      if (kDebugMode) print(object);
    },
  ));

  static Dio get dio => _dio;

  /// 공통 헤더 생성
  static Future<Map<String, String>> buildHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
