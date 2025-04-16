import 'package:see_write_say/core/data/shared_prefs_service.dart';
import 'package:see_write_say/core/presentation/helpers/snackbar_helper.dart';
import 'package:see_write_say/core/helpers/system/url_launcher_helper.dart';
import 'package:see_write_say/features/user/dto/user_profile_dto.dart';
import 'package:see_write_say/core/logic/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/app/constants/api_constants.dart';

import 'package:see_write_say/features/user/api/user_api_service.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isLoggedIn = false;
  UserProfileDto? _userProfile;

  UserProfileDto? get userProfile => _userProfile;

  LoginProvider() {
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    isLoggedIn = await StorageService.checkLoginStatus();
    notifyListeners();
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      await UrlLauncherHelper.openExternal(ApiConstants.loginUrl);
      await StorageService.save('isLoggedIn', true);
      isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      SnackbarHelper.showError(context, e);
    }
  }

  Future<void> loginAsGuest(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await _saveGuestLogin();
      isLoggedIn = true;
      notifyListeners();
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
      final profile = await UserApiService.getCurrentUserProfile();
      _userProfile = profile;

      notifyListeners();

      final hasProfile = (profile.nickname?.isNotEmpty ?? false) &&
          (profile.avatar?.isNotEmpty ?? false);

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
