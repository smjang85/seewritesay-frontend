import 'package:SeeWriteSay/dto/image_dto.dart';
import 'package:SeeWriteSay/screens/history/history_reading_screen.dart';
import 'package:SeeWriteSay/screens/user/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:SeeWriteSay/screens/login/login_screen.dart';
import 'package:SeeWriteSay/screens/picture/picture_screen.dart';
import 'package:SeeWriteSay/screens/reading/reading_screen.dart';
import 'package:SeeWriteSay/screens/writing/writing_screen.dart';
import 'package:SeeWriteSay/screens/auth/auth_callback_screen.dart';
import 'package:SeeWriteSay/screens/history/history_writing_screen.dart';

final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true, // 로그 출력용
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/profileSetup',
      name: 'profileSetup',
      builder: (context, state) => UserProfileScreen(),
    ),
    GoRoute(
      path: '/picture',
      name: 'picture',
      builder: (context, state) => PictureScreen(),
    ),
    GoRoute(
      path: '/writing',
      name: 'writing',
      builder: (context, state) {
        final imageId = int.tryParse(state.uri.queryParameters['imageId'] ?? '0') ?? 0;
        final imagePath = state.uri.queryParameters['imagePath'] ?? '';
        final imageName = state.uri.queryParameters['imageName'] ?? 'Untitled';
        final imageDescription = state.uri.queryParameters['imageDescription'] ?? '';
        final sentence = state.uri.queryParameters['sentence']; // ✅ 추가

        final imageDto = ImageDto(
          id: imageId,
          path: imagePath,
          name: imageName,
          description: imageDescription,
        );

        return WritingScreen(
          imageDto: imageDto,
          initialSentence: sentence, // ✅ 여기도 추가
        );
      },
    ),
    GoRoute(
      name: 'reading',
      path: '/reading',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final sentence = extra?['sentence'] as String?;
        final imageDto = extra?['imageDto'] as ImageDto?;

        return MaterialPage(
          child: ReadingScreen(
            sentence: sentence,
            imageDto: imageDto,
          ),
        );
      },
    ),
    GoRoute(
      path: '/historyWriting',
      name: 'historyWriting',
      builder: (context, state) {
        final initialWithCategory = state.uri.queryParameters['initialWithCategory'] == 'true';
        final imageIdParam = state.uri.queryParameters['imageId'];
        final imageId = imageIdParam != null ? int.tryParse(imageIdParam) : null;

        return HistoryWritingScreen(
          initialWithCategory: initialWithCategory,
          imageId: imageId,
        );
      },
    ),
    GoRoute(
      path: '/historyReading',
      name: 'historyReading',
      builder: (context, state) => HistoryReadingScreen(),
    ),
    GoRoute(
      path: '/googleAuth/callback',
      name: 'googleAuthCallback',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        debugPrint("✅ token from query: $token");
        return AuthCallbackScreen(token: token);
      },
    ),
  ],
  redirect: (context, state) {
    // 여기에 필요한 리디렉션 처리 로직을 넣어도 되고, 없다면 null
    return null;
  },
);
