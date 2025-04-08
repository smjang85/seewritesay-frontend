import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get loginUrl => '$baseUrl${dotenv.env['GOOGLE_LOGIN_URL']!}';

  static String get aiFeedbackUrl => '$baseUrl/api/v1/ai/feedback';
  static String get aiFeedbackGenerateUrl => '$baseUrl/api/v1/ai/feedback/generate';

  static String get userFeedbackUrl => '$baseUrl/api/v1/user/feedback';

  static String get userSettingsUrl => '$baseUrl/api/v1/user/settings';
  static String get userHelloUrl => '$baseUrl/api/v1/user/hello';

  static String get imagesUrl => '$baseUrl/api/v1/images';

  static String get writingHistoryUrl => '$baseUrl/api/v1/writing/history';
}
