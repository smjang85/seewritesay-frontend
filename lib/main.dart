import 'package:firebase_core/firebase_core.dart';
import 'package:see_write_say/features/user/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:see_write_say/core/router/router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'package:see_write_say/features/image/providers/image_list_provider.dart';
import 'package:see_write_say/features/login/providers/login_provider.dart';
import 'package:see_write_say/features/picture/providers/picture_provider.dart';
import 'package:see_write_say/features/reading/providers/reading_provider.dart';
import 'package:see_write_say/features/history/providers/history_writing_provider.dart';
import 'package:see_write_say/core/logic/session_manager.dart';

import 'package:see_write_say/core/monitor/user_activity_monitor.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized(); // ✅ 바인딩 한 번만 호출
  FlutterNativeSplash.preserve(widgetsBinding: binding);    // ✅ 이 위치가 맞음

  await Firebase.initializeApp(); // ✅ Firebase 초기화는 그 다음

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  await dotenv.load(fileName: flavor == 'prod' ? '.env.prod' : '.env.dev');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageListProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => PictureProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => HistoryWritingProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => SessionManager()),
      ],
      child: const UserActivityMonitor(
        child: SeeWriteSayApp(),
      ),
    ),
  );
}

class SeeWriteSayApp extends StatelessWidget {
  const SeeWriteSayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'See Write Say',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 바디 기본 배경색
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,       // 앱바 배경 흰색
          foregroundColor: Colors.black,       // 앱바 텍스트/아이콘 검정
          elevation: 1,                         // 앱바 그림자 최소화
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
        ).copyWith(
          secondary: Colors.indigoAccent,
        ),
      ),

      routerConfig: appRouter,
    );
  }
}
