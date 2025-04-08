import 'package:flutter/material.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isLoggedIn = false;

  LoginProvider() {
    _loadLoginState(); // 앱 시작 시 로그인 상태 체크
  }

  Future<void> _loadLoginState() async {
    final status = await CommonLogicService.checkLoginStatus(); // ✅ SharedPreferences 등으로부터
    isLoggedIn = status;
    notifyListeners();
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      await CommonLogicService.launchUrlExternal(ApiConstants.loginUrl);
      await CommonLogicService.savePreference('isLoggedIn', true); // ✅ 저장
      isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      CommonLogicService.showSnackBar(context, "구글 로그인에 실패했어요.");
    }
  }

  Future<void> loginAsGuest(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      saveGuestLogin();
      isLoggedIn = true;
      notifyListeners();
      if (context.mounted) {
        NavigationHelpers.goToPictureScreen(context);
      }
    } catch (e) {
      debugPrint("❌ 게스트 로그인 실패: $e");
      CommonLogicService.showSnackBar(context, "게스트 로그인에 실패했어요.");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveGuestLogin() async {
    await CommonLogicService.savePreference('jwt_token', 'dummy_token');
    await CommonLogicService.savePreference('guest_user', true);
    await CommonLogicService.savePreference('isLoggedIn', true);
  }


  Future<void> logout(BuildContext context) async {
    await CommonLogicService.removePreferences(['jwt_token', 'guest_user', 'isLoggedIn']);
    if (context.mounted) {
      NavigationHelpers.goToLoginScreen(context);
    }
  }

}

