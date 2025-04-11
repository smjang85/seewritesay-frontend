import 'package:flutter/material.dart';
import 'package:SeeWriteSay/router/router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'package:SeeWriteSay/providers/image/image_list_provider.dart';
import 'package:SeeWriteSay/providers/login/login_provider.dart';
import 'package:SeeWriteSay/providers/picture/picture_provider.dart';
import 'package:SeeWriteSay/providers/reading/reading_provider.dart';
import 'package:SeeWriteSay/providers/history/history_writing_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

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
