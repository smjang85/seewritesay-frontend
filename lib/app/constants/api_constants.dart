import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get loginUrl => '$baseUrl${dotenv.env['GOOGLE_LOGIN_URL']!}';

  // 피드백 생성 URL
  static String get aiFeedbackGenerateWritingUrl => '$baseUrl/api/v1/ai/feedback/generate/writing';
  static String get aiFeedbackGenerateReadingUrl => '$baseUrl/api/v1/ai/feedback/generate/reading';

  // 유저가 사용가능한 피드백 조회, 차감 URL
  static String get userFeedbackUrl => '$baseUrl/api/v1/user/feedback';
  static String get userFeedbackWritingDecrementUrl => '$baseUrl/api/v1/user/feedback/writing/decrement';
  static String get userFeedbackReadingDecrementUrl => '$baseUrl/api/v1/user/feedback/reading/decrement';

  // 유저 프로필 관련 URL
  static String get userCheckNicknameUrl => '$baseUrl/api/v1/user/check-nickname';
  static String get userGenerateNicknameUrl => '$baseUrl/api/v1/user/generate-nickname';
  static String get userUpdateProfileUrl => '$baseUrl/api/v1/user/update-profile';
  static String get userCurrentProfileUrl => '$baseUrl/api/v1/user/current-user-profile';
  static String get userDeleteAccountUrl => '$baseUrl/api/v1/user/delete';

  // 이미지 관련 URL
  static String get imagesUrl => '$baseUrl/api/v1/images';
  static String get imagesCategoriesUrl => '$baseUrl/api/v1/images/categories';

  // 유저 작문 / 읽기 히스토리 관련 URL
  static String get historyWritingUrl => '$baseUrl/api/v1/history/writing';
  static String get historyWritingWithCategoryUrl => '$baseUrl/api/v1/history/writing/with-category';
  static String get historyWritingDeleteUrl => '$baseUrl/api/v1/history/writing';

  // 세션 리플레시
  static String get authRefreshUrl => '$baseUrl/api/v1/auth/refresh';
}
