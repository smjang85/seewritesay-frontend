import 'package:SeeWriteSay/providers/login/login_provider.dart';
import 'package:SeeWriteSay/providers/picture/picture_provider.dart';
import 'package:SeeWriteSay/providers/reading/reading_provider.dart';
import 'package:SeeWriteSay/providers/image/image_list_provider.dart';
import 'package:SeeWriteSay/providers/history/history_writing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'router/router.dart'; // go_router 설정 파일

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );

  // ✅ FLAVOR 환경값에 따라 .env 파일 선택
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  await dotenv.load(fileName: flavor == 'prod' ? '.env.prod' : '.env.dev');

  debugPrint('✅ 앱 시작됨. 현재 FLAVOR: $flavor');
  debugPrint('✅ 현재 BASE_URL: ${dotenv.env['BASE_URL']}');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageListProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => PictureProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => HistoryWritingProvider()),

      ],
      child: const SeeWriteSayApp(),
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
      theme: ThemeData(primarySwatch: Colors.indigo),
      routerConfig: appRouter, // ✅ GoRouter 적용
    );
  }
}
