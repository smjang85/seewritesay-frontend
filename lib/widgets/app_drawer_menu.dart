import 'package:flutter/material.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';

class AppDrawerMenu extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback? onLogout;

  const AppDrawerMenu({
    Key? key,
    required this.isLoggedIn,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          ListTile(
            leading: Icon(Icons.edit_note),
            title: Text("진행한 작문"),
            onTap: () {
              Navigator.pop(context);
              NavigationHelpers.goToHistoryWritingScreen(context, withCategory: true);
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
              Navigator.of(context).pop(); // 예시로 닫기만
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: Colors.indigo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_circle, color: Colors.white, size: 48),
          SizedBox(height: 8),
          Text(
            isLoggedIn ? "로그인됨" : "로그인이 필요해요",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
