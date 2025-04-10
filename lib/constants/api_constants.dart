import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get loginUrl => '$baseUrl${dotenv.env['GOOGLE_LOGIN_URL']!}';


  static String get aiFeedbackGenerateUrl => '$baseUrl/api/v1/ai/feedback/generate';

  static String get userFeedbackUrl => '$baseUrl/api/v1/user/feedback';
  static String get userSettingsUrl => '$baseUrl/api/v1/user/settings';

  static String get imagesUrl => '$baseUrl/api/v1/images';
  static String get imagesCategoriesUrl => '$baseUrl/api/v1/images/categories';

  static String get historyWritingUrl => '$baseUrl/api/v1/history/writing';
  static String get historyWritingWithCategoryUrl => '$baseUrl/api/v1/history/writing/with-category';
  static String get historyWritingDeleteUrl => '$baseUrl/api/v1/history/writing';
}
