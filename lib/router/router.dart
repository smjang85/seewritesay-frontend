import 'package:SeeWriteSay/screen/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:SeeWriteSay/screen/backup/splash_screen.dart';
import 'package:SeeWriteSay/screen/picture/picture_screen.dart';
import 'package:SeeWriteSay/screen/reading/reading_screen.dart';
import 'package:SeeWriteSay/screen/writing/writing_screen.dart';
import 'package:SeeWriteSay/screen/writing/writing_history_screen.dart';
import 'package:SeeWriteSay/screen/oauth2/auth_callback_screen.dart';
import 'package:SeeWriteSay/model/img_info.dart';

final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true, // 로그 출력용
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => SplashScreen(),
    ),
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
        final imgInfo = state.extra as ImgInfo?;
        return WritingScreen(imgInfo: imgInfo);
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
      path: '/history',
      name: 'history',
      builder: (context, state) => const WritingHistoryScreen(),
    ),
    GoRoute(
      path: '/googleAuth/callback',
      name: 'googleAuthCallback',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        print("✅ token from query: $token");
        return AuthCallbackScreen(token: token);
      },
    ),
  ],
  redirect: (context, state) {
    // 여기에 필요한 리디렉션 처리 로직을 넣어도 되고, 없다면 null
    return null;
  },
);
