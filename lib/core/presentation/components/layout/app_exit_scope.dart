import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemNavigator를 위해 필요

class AppExitScope extends StatelessWidget {
  final Widget child;

  const AppExitScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("앱 종료"),
            content: const Text("앱을 종료하시겠어요?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("아니오"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("예"),
              ),
            ],
          ),
        );

        if (shouldExit ?? false) {
          SystemNavigator.pop(); // 앱 종료
        }
      },
      child: child,
    );
  }
}
