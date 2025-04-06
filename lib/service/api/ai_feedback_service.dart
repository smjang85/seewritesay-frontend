import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class AIFeedbackService {

  static Future<Map<String, String>> fetchFeedback(String userText, String imageId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("❌ JWT 토큰이 없습니다. 로그인 필요.");
    }

    final response = await http.post(
      Uri.parse(ApiConstants.feedbackUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sentence': userText,
        'imageId': imageId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'correction': data['correction'] ?? userText,
        'feedback': data['feedback'] ?? '',
      };
    } else {
      throw Exception("❌ GPT 피드백 요청 실패: ${response.statusCode} ${response.body}");
    }
  }
}
