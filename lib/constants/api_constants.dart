import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get loginUrl => '$baseUrl' + dotenv.env['GOOGLE_LOGIN_URL']!;

  static String get feedbackUrl => '$baseUrl/api/v1/feedback';
  static String get generateFeedback => '$baseUrl/api/v1/feedback/generate';
  static String get userSettings => '$baseUrl/api/v1/protected/settings';
  static String get protectedHello => '$baseUrl/api/v1/protected/hello';

  static String get imgList => '$baseUrl/api/v1/images';
}
