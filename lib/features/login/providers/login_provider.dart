import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/core/data/shared_prefs_service.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:see_write_say/core/logic/session_manager.dart';
import 'package:see_write_say/core/presentation/helpers/snackbar_helper.dart';
import 'package:see_write_say/features/login/api/auth_api_service.dart';
import 'package:see_write_say/features/user/api/user_api_service.dart';
import 'package:see_write_say/features/user/dto/user_profile_dto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isLoggedIn = false;
  UserProfileDto? _userProfile;
  UserProfileDto? get userProfile => _userProfile;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;


  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  LoginProvider() {
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    isLoggedIn = await StorageService.checkLoginStatus();
    debugPrint("🔄 [_loadLoginState] isLoggedIn=$isLoggedIn");
    notifyListeners();
  }

  void refreshLoginState() {
    _loadLoginState();
  }

  Future<void> loginWithApple(BuildContext context) async {
    if (!Platform.isIOS) return;

    isLoading = true;
    notifyListeners();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);

      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) throw Exception("Apple 로그인: Firebase ID 토큰이 null입니다.");

      debugPrint("🍎 Firebase ID Token (Apple): $firebaseIdToken");

      final jwtToken = await AuthApiService.loginWithGoogleIdToken(firebaseIdToken);
      debugPrint("✅ [서버 응답 JWT] token: $jwtToken");

      await StorageService.save('jwt_token', jwtToken);
      await StorageService.save('isLoggedIn', true);

      notifyListeners();

      final profile = await UserApiService.getProfileCurrentUser();
      _userProfile = profile;

      final hasProfile = (profile.nickname?.isNotEmpty ?? false) && (profile.avatar?.isNotEmpty ?? false);

      final sessionManager = context.read<SessionManager>();
      sessionManager.init();
      sessionManager.startSessionTimer(context);

      if (context.mounted) {
        hasProfile
            ? NavigationHelpers.goToPictureScreen(context)
            : NavigationHelpers.goToProfileSetupScreen(context);
      }
    } catch (e) {
      debugPrint("❌ Apple 로그인 실패: $e");
      SnackbarHelper.showError(context, e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("⚠️ Google 로그인 취소됨");
        isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 🔥 Firebase 인증용 credential 생성
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 🔥 Firebase에 로그인
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // ✅ Firebase가 발급한 ID Token 받기
      final String? firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) throw Exception("Firebase ID 토큰이 null입니다.");

      debugPrint("✅ Firebase ID Token: $firebaseIdToken");

      // 🛰️ 서버로 JWT 요청
      final jwtToken = await AuthApiService.loginWithGoogleIdToken(firebaseIdToken);
      debugPrint("✅ [서버 응답 JWT] token: $jwtToken");

      await StorageService.save('jwt_token', jwtToken);
      await StorageService.save('isLoggedIn', true);

      notifyListeners();

      final profile = await UserApiService.getProfileCurrentUser();
      _userProfile = profile;

      final hasProfile = (profile.nickname?.isNotEmpty ?? false) && (profile.avatar?.isNotEmpty ?? false);

      final sessionManager = context.read<SessionManager>();
      sessionManager.init();
      sessionManager.startSessionTimer(context);

      if (context.mounted) {
        hasProfile
            ? NavigationHelpers.goToPictureScreen(context)
            : NavigationHelpers.goToProfileSetupScreen(context);
      }
    } catch (e) {
      debugPrint("❌ 구글 로그인 실패: $e");
      SnackbarHelper.showError(context, e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAsGuest(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await _saveGuestLogin();
      isLoggedIn = true;

      if (context.mounted) {
        NavigationHelpers.goToPictureScreen(context);
      }
    } catch (e) {
      debugPrint("❌ 게스트 로그인 실패: $e");
      SnackbarHelper.showError(context, e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveGuestLogin() async {
    await StorageService.save('jwt_token', 'dummy_token');
    await StorageService.save('guest_user', true);
    await StorageService.save('isLoggedIn', true);
  }

  Future<void> handleAuthCallback(String token, BuildContext context) async {
    await StorageService.save('jwt_token', token);
    await StorageService.save('isLoggedIn', true);
    isLoggedIn = true;

    try {
      final profile = await UserApiService.getProfileCurrentUser();
      _userProfile = profile;

      final hasProfile =
          (profile.nickname?.isNotEmpty ?? false) && (profile.avatar?.isNotEmpty ?? false);

      if (context.mounted) {
        hasProfile
            ? NavigationHelpers.goToPictureScreen(context)
            : NavigationHelpers.goToProfileSetupScreen(context);
      }
    } catch (e) {
      debugPrint("❌ 프로필 조회 실패: $e");
      if (context.mounted) {
        NavigationHelpers.goToProfileSetupScreen(context);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    await StorageService.removeMultiple([
      'jwt_token',
      'guest_user',
      'isLoggedIn',
    ]);

    isLoggedIn = false;
    _userProfile = null;

    final sessionManager = context.read<SessionManager>();
    sessionManager.disposeSession();

    notifyListeners();

    if (context.mounted) {
      NavigationHelpers.goToLoginScreen(context);
    }
  }
}
