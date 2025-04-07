import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get loginUrl => '$baseUrl' + dotenv.env['GOOGLE_LOGIN_URL']!;

  static String get feedbackUrl => '$baseUrl/api/v1/feedback';
  static String get feedbackGenerateUrl => '$baseUrl/api/v1/feedback/generate';

  static String get userSettingsUrl => '$baseUrl/api/v1/user/settings';
  static String get userHelloUrl => '$baseUrl/api/v1/user/hello';

  static String get imagesUrl => '$baseUrl/api/v1/images';
}
