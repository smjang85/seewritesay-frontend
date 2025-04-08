import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // ✅ go_router import
import 'package:shared_preferences/shared_preferences.dart';

class AuthCallbackScreen extends StatefulWidget {
  final String? token;

  const AuthCallbackScreen({super.key, this.token});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint("전달된 토큰: ${widget.token}");
    _handleAuthToken();
  }

  Future<void> _handleAuthToken() async {
    if (widget.token == null) {
      debugPrint('❌ 토큰이 null입니다!');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', widget.token!);

    // ✅ 저장이 완료된 후 화면 이동
    if (!mounted) return;
    context.pushReplacementNamed('picture');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // 로딩 중 표시
      ),
    );
  }
}
