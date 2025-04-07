
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/constants/api_constants.dart';


class AuthApiService {

  // ✅ 보호된 API 호출 (예시: 로그인 테스트용)
  static Future<String> fetchProtectedMessage() async {
    final token = await CommonLogicService.getToken();
    if (token == null) throw Exception("❌ JWT 토큰이 없습니다. 로그인 필요.");

    final response = await http.get(
      Uri.parse(ApiConstants.userHelloUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("❌ API 호출 실패: ${response.statusCode} ${response.body}");
    }
  }

}
