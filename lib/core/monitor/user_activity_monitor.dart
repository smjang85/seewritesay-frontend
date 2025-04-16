import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/core/logic/session_manager.dart';

class UserActivityMonitor extends StatelessWidget {
  final Widget child;

  const UserActivityMonitor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<SessionManager>().onUserActivity(context),
      behavior: HitTestBehavior.translucent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          context.read<SessionManager>().onUserActivity(context);
          return false;
        },
        child: child,
      ),
    );
  }
}
