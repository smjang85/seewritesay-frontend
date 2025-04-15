import 'dart:async';
import 'package:SeeWriteSay/constants/constants.dart';
import 'package:SeeWriteSay/services/api/auth/auth_api_service.dart';
import 'package:SeeWriteSay/utils/dialog_popup_helper.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager extends ChangeNotifier {
  late DateTime tokenExpirationTime;
  Timer? expirationTimer;
  bool _isSessionExpired = false;

  bool get isSessionExpired => _isSessionExpired;

  /// 세션 타이머 시작 (연장 포함)
  void startSessionTimer(BuildContext context) {
    _cancelTimerIfExists();

    tokenExpirationTime = DateTime.now().add(
      Duration(milliseconds: Constants.sessionExpirationTime),
    );

    final durationUntilPopup = tokenExpirationTime
        .subtract(const Duration(seconds: 60))
        .difference(DateTime.now());

    expirationTimer = Timer(durationUntilPopup, () {
      _showSessionExtendPopup(context);
    });

    debugPrint("🕒 세션 타이머 시작됨. 팝업까지: ${durationUntilPopup.inSeconds}s");
  }

  /// 세션 연장 팝업 표시
  void _showSessionExtendPopup(BuildContext context) {
    DialogPopupHelper.showCountdownBlockingDialog(
      context: context,
      countdownSeconds: 30,
      onTimeout: () => _showSessionExpiredPopup(context),
      onExtend: () => _extendSession(context),
    );
  }

  /// 세션 연장 로직 (성공 시 타이머 재시작)
  void _extendSession(BuildContext context) async {
    try {
      final newToken = await AuthApiService.refreshToken();
      if (newToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', newToken);
        debugPrint("✅ 새로운 JWT 토큰 저장 완료");

        startSessionTimer(context); // 🔁 타이머 재시작
      } else {
        debugPrint("❌ 토큰 갱신 실패 (null)");
        _showSessionExpiredPopup(context);
      }
    } catch (e) {
      debugPrint("❌ 예외 발생 during refresh: $e");
      _showSessionExpiredPopup(context);
    }
  }

  /// 세션 만료 팝업 표시
  void _showSessionExpiredPopup(BuildContext context) {
    _cancelTimerIfExists();

    DialogPopupHelper.showBlockingDialog(
      context: context,
      title: "로그인 세션 만료",
      content: "세션이 만료되었습니다. 다시 로그인 해주세요.",
      confirmText: "확인",
      onConfirm: () {
        NavigationHelpers.goToLoginScreen(context);
      },
    );

    _isSessionExpired = true;
    notifyListeners();
  }

  /// 명시적 만료 처리 (예: 서버 401 응답 시)
  void handleTokenExpired(BuildContext context) {
    _showSessionExpiredPopup(context);
  }

  /// 기존 타이머가 있으면 취소
  void _cancelTimerIfExists() {
    if (expirationTimer?.isActive ?? false) {
      expirationTimer?.cancel();
      debugPrint("⏹ 기존 세션 타이머 취소됨");
    }
  }
}
