import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get loginUrl => '$baseUrl${dotenv.env['GOOGLE_LOGIN_URL']!}'; //기존 리다이렉트 방식

  static String get googleLoginUrl => '$baseUrl/api/v1/auth/google-login'; // firebase 사용
  // AI Feedback 생성 URL
  static String get aiFeedbackGenerateWritingUrl => '$baseUrl/api/v1/ai/feedback/generate/writing';
  static String get aiFeedbackGenerateReadingUrl => '$baseUrl/api/v1/ai/feedback/generate/reading';

  // User Feedback 조회, 차감 URL
  static String get userFeedbackUrl => '$baseUrl/api/v1/user/feedback';
  static String get userFeedbackWritingDecrementUrl => '$baseUrl/api/v1/user/feedback/writing/decrement';
  static String get userFeedbackReadingDecrementUrl => '$baseUrl/api/v1/user/feedback/reading/decrement';

  // User Profile 관련 URL
  static String get userDeleteAccountUrl => '$baseUrl/api/v1/user/delete';
  static String get userProfileCheckNicknameUrl => '$baseUrl/api/v1/user/profile/check-nickname';
  static String get userProfileGenerateNicknameUrl => '$baseUrl/api/v1/user/profile/generate-nickname';
  static String get userProfileUpdateUrl => '$baseUrl/api/v1/user/profile/update';
  static String get userProfileCurrentUserUrl => '$baseUrl/api/v1/user/profile/current-user';

  // Image 관련 URL
  static String get imagesUrl => '$baseUrl/api/v1/images';
  static String get imagesCategoriesUrl => '$baseUrl/api/v1/images/categories';

  // User History 관련 URL
  static String get historyWritingUrl => '$baseUrl/api/v1/history/writing';
  static String get historyWritingWithCategoryUrl => '$baseUrl/api/v1/history/writing/with-category';
  static String get historyWritingDeleteUrl => '$baseUrl/api/v1/history/writing';

  //
  static String get storyUrl => '$baseUrl/api/v1/story';

  // Session 갱신 URL
  static String get authRefreshUrl => '$baseUrl/api/v1/auth/refresh';
}
