import 'package:flutter/material.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/services/api/user/user_api_service.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/dto/user_profile_response_dto.dart'; // 유저 응답 DTO 경로에 따라 조정 필요

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isLoggedIn = false;
  UserProfileResponseDto? _userProfile;

  UserProfileResponseDto? get userProfile => _userProfile;

  LoginProvider() {
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    isLoggedIn = await CommonLogicService.checkLoginStatus();
    notifyListeners();
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      await CommonLogicService.launchUrlExternal(ApiConstants.loginUrl);
      await CommonLogicService.savePreference('isLoggedIn', true);
      isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      CommonLogicService.showErrorSnackBar(context, e);
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
      CommonLogicService.showErrorSnackBar(context, e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveGuestLogin() async {
    await CommonLogicService.savePreference('jwt_token', 'dummy_token');
    await CommonLogicService.savePreference('guest_user', true);
    await CommonLogicService.savePreference('isLoggedIn', true);
  }

  Future<void> handleAuthCallback(String token, BuildContext context) async {
    await CommonLogicService.savePreference('jwt_token', token);
    await CommonLogicService.savePreference('isLoggedIn', true);
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
    await CommonLogicService.removePreferences([
      'jwt_token',
      'guest_user',
      'isLoggedIn',
    ]);
    isLoggedIn = false;
    _userProfile = null;
    notifyListeners();

    if (context.mounted) {
      NavigationHelpers.goToLoginScreen(context);
    }
  }
}
