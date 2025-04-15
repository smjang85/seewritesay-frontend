import 'package:SeeWriteSay/providers/user/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
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
          _buildHeader(context),// 👤 상단 사용자 정보
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
          isLoggedIn
              ? ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text("로그아웃"),
            onTap: onLogout,
          )
              : ListTile(
            leading: Icon(Icons.login),
            title: Text("로그인"),
            onTap: () {
              Navigator.of(context).pop();
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
                  child: Image.asset(avatarPath, width: 64, height: 64, fit: BoxFit.cover),
                )
                    : const Icon(Icons.account_circle, color: Colors.white, size: 64),
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
