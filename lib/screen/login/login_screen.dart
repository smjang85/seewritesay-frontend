
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SeeWriteSay/service/api/api_service.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove(); // ✅ 스플래시 제거
  }

  Future<void> _handleLogin(BuildContext context) async {
    var loginUrl = ApiConstants.loginUrl;
    await ApiService.launchUrlExternal(loginUrl); // 실제 로그인 URL로 연결
  }

  Future<void> _handleGuestLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', 'dummy_token'); // 체험 로그인
    await prefs.setBool('guest_user', true);

    if (context.mounted) {
      context.goNamed('picture');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text(
                'Welcome to See Write Say!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Google 로그인'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleLogin(context),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _handleGuestLogin(context),
                child: const Text(
                  '비로그인으로 체험하기',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
