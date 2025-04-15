import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get loginUrl => '$baseUrl${dotenv.env['GOOGLE_LOGIN_URL']!}';


  static String get aiFeedbackGenerateWritingUrl => '$baseUrl/api/v1/ai/feedback/generate/writing';
  static String get aiFeedbackGenerateReadingUrl => '$baseUrl/api/v1/ai/feedback/generate/reading';

  static String get userFeedbackUrl => '$baseUrl/api/v1/user/feedback';
  static String get userFeedbackWritingDecrementUrl => '$baseUrl/api/v1/user/feedback/writing/decrement';

  static String get userCheckNicknameUrl => '$baseUrl/api/v1/user/check-nickname';
  static String get userGenerateNicknameUrl => '$baseUrl/api/v1/user/generate-nickname';
  static String get userUpdateProfileUrl => '$baseUrl/api/v1/user/update-profile';
  static String get userCurrentProfileUrl => '$baseUrl/api/v1/user/current-user-profile';

  static String get imagesUrl => '$baseUrl/api/v1/images';
  static String get imagesCategoriesUrl => '$baseUrl/api/v1/images/categories';

  static String get historyWritingUrl => '$baseUrl/api/v1/history/writing';
  static String get historyWritingWithCategoryUrl => '$baseUrl/api/v1/history/writing/with-category';
  static String get historyWritingDeleteUrl => '$baseUrl/api/v1/history/writing';

  static String get authRefreshUrl => '$baseUrl/api/v1/auth/refresh';
}
