import 'package:see_write_say/features/user/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:provider/provider.dart';

class AppDrawerMenu extends StatelessWidget {
  final bool isLoggedIn;
  final String? nickname;
  final String? avatar;
  final VoidCallback? onLogout;

  const AppDrawerMenu({
    Key? key,
    required this.isLoggedIn,
    this.nickname,
    this.avatar,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<UserProfileProvider>().initializeProfile();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context), // 👤 상단 사용자 정보
          ListTile(
            leading: Icon(Icons.edit_note),
            title: Text("진행한 작문"),
            onTap: () {
              Navigator.pop(context);
              NavigationHelpers.goToHistoryWritingScreen(
                context,
                withCategory: true,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.record_voice_over),
            title: Text("녹음한 리딩"),
            onTap: () {
              Navigator.pop(context);
              NavigationHelpers.goToHistoryReadingScreen(context);
            },
          ),
          const Divider(),
          if (isLoggedIn)
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent),
              title: Text("로그아웃"),
              onTap: onLogout,
            ),
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("회원 탈퇴", style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("회원 탈퇴"),
                    content: const Text("정말로 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("취소"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("탈퇴", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await context.read<UserProfileProvider>().deleteAccountAndNavigate(context);
                    if (onLogout != null) onLogout!();
                  } catch (e) {
                    debugPrint("❌ 탈퇴 실패: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("회원 탈퇴 중 오류가 발생했습니다.")),
                    );
                  }
                }
              },
            ),
          if (!isLoggedIn)
            ListTile(
              leading: Icon(Icons.login),
              title: Text("로그인"),
              onTap: () {
                Navigator.of(context).pop();
                // 로그인 화면으로 이동하려면 필요 시 여기에 추가
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, child) {
        final avatarPath = provider.selectedAvatar ?? '';
        final nickname = provider.nicknameController.text.isNotEmpty
            ? provider.nicknameController.text
            : '사용자';

        return DrawerHeader(
          decoration: const BoxDecoration(color: Colors.indigo),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              NavigationHelpers.pushToProfileSetupScreen(context);
            },
            child: Row(
              children: [
                avatarPath.isNotEmpty
                    ? ClipOval(
                  child: Image.asset(
                    avatarPath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(Icons.account_circle,
                    color: Colors.white, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    nickname,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
