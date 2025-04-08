import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:SeeWriteSay/screens/login/login_screen.dart';
import 'package:SeeWriteSay/screens/picture/picture_screen.dart';
import 'package:SeeWriteSay/screens/reading/reading_screen.dart';
import 'package:SeeWriteSay/screens/writing/writing_screen.dart';
import 'package:SeeWriteSay/screens/writing/writing_history_screen.dart';
import 'package:SeeWriteSay/screens/auth/auth_callback_screen.dart';
import 'package:SeeWriteSay/models/image_model.dart';

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

        final imageModel = ImageModel(
          id: imageId,
          path: imagePath,
          name: imageName,
          description: imageDescription,
        );

        return WritingScreen(
          imageModel: imageModel,
          initialSentence: sentence, // ✅ 여기도 추가
        );
      },
    ),
    GoRoute(
      path: '/reading',
      name: 'reading',
      builder: (context, state) {
        final text = state.uri.queryParameters['text'] ?? '';
        return ReadingScreen(sentence: text);
      },
    ),
    GoRoute(
      path: '/writingHistory',
      name: 'writingHistory',
      builder: (context, state) {
        final imageIdParam = state.uri.queryParameters['imageId'];
        final imageId = int.tryParse(imageIdParam ?? '');
        return WritingHistoryScreen(imageId: imageId);
      },
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
