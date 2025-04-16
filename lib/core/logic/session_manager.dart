import 'dart:async';
import 'package:see_write_say/app/constants/constants.dart';
import 'package:see_write_say/features/login/api/auth_api_service.dart';
import 'package:see_write_say/core/presentation/dialog/dialog_popup_helper.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SessionManager extends ChangeNotifier with WidgetsBindingObserver {
  late DateTime tokenExpirationTime;
  Timer? expirationTimer;
  BuildContext? _lastContext;
  bool _isSessionExpired = false;

  bool get isSessionExpired => _isSessionExpired;

  DateTime? _lastRefresh;

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void disposeSession() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimerIfExists();
  }

  void onUserActivity(BuildContext context) {
    final now = DateTime.now();
    if (_lastRefresh == null ||
        now.difference(_lastRefresh!) > const Duration(minutes: 5)) {
      _lastRefresh = now;
      _extendSession(); // refreshToken API 호출
    }
  }

  void startSessionTimer(BuildContext context) {
    _cancelTimerIfExists();

    _lastContext = _findRootContext(context); // 💡 안전한 context 저장

    tokenExpirationTime = DateTime.now().add(
      Duration(milliseconds: Constants.sessionExpirationTime),
    );

    final durationUntilPopup = tokenExpirationTime
        .subtract(const Duration(seconds: 5))
        .difference(DateTime.now());

    expirationTimer = Timer(durationUntilPopup, () {
      debugPrint("⏱ 타이머 만료됨, 팝업 호출 시도");
      _showSessionExtendPopup();
    });

    debugPrint("🕒 세션 타이머 시작됨. 팝업까지: ${durationUntilPopup.inSeconds}s");
  }

  BuildContext _findRootContext(BuildContext context) {
    BuildContext ctx = context;
    while (Navigator.of(ctx).context != ctx) {
      ctx = Navigator.of(ctx).context;
    }
    return ctx;
  }

  bool _isContextValid() {
    return _lastContext?.mounted ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() {
    if (!_isContextValid()) return;

    final now = DateTime.now();
    final remaining = tokenExpirationTime.difference(now);

    if (remaining.inSeconds <= 0) {
      _showSessionExpiredPopup();
    } else if (remaining.inSeconds <=
        Constants.sessionExpirationCountdownSeconds) {
      _showSessionExtendPopup();
    } else {
      debugPrint("📱 앱 복귀됨. 남은 세션 시간: ${remaining.inSeconds}s");
    }
  }

  void _showSessionExtendPopup() {
    if (_lastContext == null) {
      debugPrint("❌ 팝업 표시 실패: _lastContext == null");
      return;
    }

    final context = _lastContext!;
    debugPrint("🧭 팝업 표시 시도 중...");
    debugPrint("📍 context: $context");
    debugPrint("📍 context.mounted: ${context.mounted}");

    if (!context.mounted) {
      debugPrint("❌ 팝업 표시 실패: context가 unmounted 상태");
      return;
    }

    // ⏳ 딜레이 추가해 안전하게 다이얼로그 실행
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!context.mounted) {
        debugPrint("❌ 딜레이 후에도 context가 unmounted 상태");
        return;
      }

      debugPrint("✅ 팝업 띄우기 실행");
      DialogPopupHelper.showCountdownBlockingDialog(
        context: context,
        countdownSeconds: Constants.sessionExpirationCountdownSeconds,
        onTimeout: _showSessionExpiredPopup,
        onExtend: _extendSession,
      );
    });
  }

  void _extendSession() async {
    try {
      final newToken = await AuthApiService.refreshToken();
      if (newToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', newToken);
        debugPrint("✅ 새로운 JWT 토큰 저장 완료");

        if (_isContextValid()) {
          startSessionTimer(_lastContext!);
        }
      } else {
        _showSessionExpiredPopup();
      }
    } catch (e) {
      debugPrint("❌ 토큰 갱신 실패: $e");
      _showSessionExpiredPopup();
    }
  }

  void _showSessionExpiredPopup() {
    _cancelTimerIfExists();

    if (!_isContextValid()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DialogPopupHelper.showBlockingDialog(
        context: _lastContext!,
        title: "로그인 세션 만료",
        content: "세션이 만료되었습니다. 다시 로그인 해주세요.",
        confirmText: "확인",
        onConfirm: () {
          NavigationHelpers.goToLoginScreen(_lastContext!);
        },
      );
    });

    _isSessionExpired = true;
    notifyListeners();
  }

  void handleTokenExpired(BuildContext context) {
    _lastContext = context;
    _showSessionExpiredPopup();
  }

  void _cancelTimerIfExists() {
    if (expirationTimer?.isActive ?? false) {
      expirationTimer?.cancel();
      debugPrint("⏹ 기존 세션 타이머 취소됨");
    }
  }
}
