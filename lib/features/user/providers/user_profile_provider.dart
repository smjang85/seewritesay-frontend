import 'package:see_write_say/core/logic/session_manager.dart';
import 'package:see_write_say/core/presentation/helpers/snackbar_helper.dart';
import 'package:see_write_say/features/user/api/user_api_service.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AgeGroup {
  final String label;
  final String value;

  const AgeGroup._(this.label, this.value);

  static const AgeGroup under6 = AgeGroup._('6세 이하', '1');
  static const AgeGroup age7to9 = AgeGroup._('7-9세', '2');
  static const AgeGroup age10to12 = AgeGroup._('10-12세', '3');
  static const AgeGroup age13to15 = AgeGroup._('13-15세', '4');
  static const AgeGroup age16to18 = AgeGroup._('16-18세', '5');
  static const AgeGroup age19to29 = AgeGroup._('19-29세', '6');
  static const AgeGroup over30 = AgeGroup._('30세 이상', '7');

  static const List<AgeGroup> all = [
    under6,
    age7to9,
    age10to12,
    age13to15,
    age16to18,
    age19to29,
    over30,
  ];

  static AgeGroup? fromValue(String? value) {
    return all.firstWhere((age) => age.value == value, orElse: () => under6);
  }
}

class UserProfileProvider extends ChangeNotifier {
  final TextEditingController nicknameController = TextEditingController();
  String? selectedAvatar;
  AgeGroup? selectedAgeGroup;
  bool nicknameChecked = false;
  String? originalNickname;

  final List<String> avatarList = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
  ];

  bool isNewUser = true; // 기본은 신규

  void initFromRouter(BuildContext context) {
    final extra =
        GoRouter
            .of(context)
            .routerDelegate
            .currentConfiguration
            .extra;
    if (extra is AgeGroup) {
      selectedAgeGroup = extra;
    } else if (extra is String) {
      selectedAgeGroup = AgeGroup.fromValue(extra);
    }
  }

  void selectAvatar(String avatar) {
    selectedAvatar = avatar;
    notifyListeners();
  }

  Future<void> checkNickname(BuildContext context) async {
    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      SnackbarHelper.show(context, '닉네임을 입력해주세요.', seconds: 1);
      return;
    }

    try {
      final isAvailable = await UserApiService.checkNicknameAvailable(nickname);

      if (isAvailable) {
        nicknameChecked = true;
        notifyListeners();
        SnackbarHelper.show(context, '✅ 사용 가능한 닉네임입니다.', seconds: 1);
      } else {
        nicknameChecked = false;
        notifyListeners();
        SnackbarHelper.show(context, '❌ 이미 사용 중인 닉네임입니다.', seconds: 1);
      }
    } catch (e) {
      SnackbarHelper.showError(context, '에러 발생: $e');
    }
  }

  Future<void> generateRandomNickname(BuildContext context) async {
    try {
      final nickname = await UserApiService.generateRandomNickname();
      nicknameController.text = nickname;
      nicknameChecked = false;
      notifyListeners();

      SnackbarHelper.show(context, '랜덤 닉네임이 생성되었습니다: $nickname', seconds: 1);
    } catch (e) {
      SnackbarHelper.showError(context, '랜덤 닉네임 생성 실패: $e');
    }
  }

  void selectAgeGroup(AgeGroup? ageGroup) {
    selectedAgeGroup = ageGroup;
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    final nickname = nicknameController.text.trim();
    final avatar = selectedAvatar;
    final ageGroup = selectedAgeGroup?.value ?? "0";

    if (nickname.isEmpty || avatar == null || ageGroup == "0") {
      SnackbarHelper.show(context, '닉네임, 아바타, 연령대를 모두 선택해주세요.', seconds: 1);
      return;
    }

    final isNicknameChanged = nickname != originalNickname;
    if (isNicknameChanged && !nicknameChecked) {
      SnackbarHelper.show(context, '닉네임 중복 확인을 해주세요.', seconds: 1);
      return;
    }

    try {
      await UserApiService.updateProfile(
        nickname: nickname,
        avatar: avatar,
        ageGroup: ageGroup,
      );

      SnackbarHelper.show(context, '✅ 프로필이 저장되었습니다.', seconds: 1);

      notifyListeners();

      if (isNewUser) {
        NavigationHelpers.goToPictureScreen(context);
      }
    } catch (e) {
      SnackbarHelper.showError(context, '프로필 저장 실패: $e');
    }
  }

  Future<void> initializeProfile() async {
    try {
      final profile = await UserApiService.getCurrentUserProfile();
      nicknameController.text = profile.nickname ?? '';
      originalNickname = profile.nickname;
      selectedAvatar =
      profile.avatar != null ? 'assets/avatars/${profile.avatar}' : null;
      selectedAgeGroup = AgeGroup.fromValue(profile.ageGroup);
      isNewUser = (profile.nickname == null || profile.nickname!.isEmpty);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 프로필 초기화 실패: $e');
    }
  }

  Future<void> deleteAccountAndNavigate(BuildContext context) async {
    try {
      await UserApiService.deleteAccount();

      // ✅ 세션 제거
      final sessionManager = context.read<SessionManager>();
      sessionManager.disposeSession();

      // ✅ 탈퇴 완료 스낵바
      SnackbarHelper.show(
        context,
        "👋 회원 탈퇴가 완료되었습니다.\n다시 찾아와 주세요!",
        seconds: 3,
      );

      // ✅ 로그인 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 500));
      NavigationHelpers.goToLoginScreen(context);
    } catch (e) {
      SnackbarHelper.showError(context, e);
      rethrow;
    }
  }
}
