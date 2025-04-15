import 'package:flutter/material.dart';
import 'package:SeeWriteSay/services/api/user/user_api_service.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';

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
    _processLoginToken();
  }

  Future<void> _processLoginToken() async {
    final token = widget.token;
    debugPrint("전달된 토큰: $token");

    if (token == null || token.isEmpty) {
      debugPrint("❌ 전달된 토큰이 없습니다.");
      return;
    }

    try {
      // ✅ 토큰 저장 및 로그인 상태 저장
      await CommonLogicService.savePreference('jwt_token', token);
      await CommonLogicService.savePreference('isLoggedIn', true);

      if (!mounted) return;

      // ✅ 프로필 조회
      final profile = await UserApiService.getCurrentUserProfile();
      debugPrint("profile.avatar: ${profile.avatar}");
      final hasProfile =
          (profile.nickname?.isNotEmpty ?? false) && (profile.avatar?.isNotEmpty ?? false);

      if (!mounted) return;

      hasProfile
          ? NavigationHelpers.goToPictureScreen(context)
          : NavigationHelpers.goToProfileSetupScreen(context);
    } catch (e) {
      debugPrint("❌ 프로필 조회 중 오류: $e");

      if (mounted) {
        NavigationHelpers.goToProfileSetupScreen(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
