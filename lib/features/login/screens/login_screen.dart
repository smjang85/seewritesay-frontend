import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/core/presentation/theme/text_styles.dart';
import 'package:see_write_say/core/presentation/theme/button_styles.dart';
import 'package:see_write_say/features/login/providers/login_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: const LoginScreenContent(),
    );
  }
}

class LoginScreenContent extends StatelessWidget {
  const LoginScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoginProvider>();

    // ✅ 스플래시 제거
    FlutterNativeSplash.remove();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to See Write Say!',
                style: kHeadingTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              provider.isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                children: [
                  if (Platform.isIOS)
                    SignInWithAppleButton(
                      onPressed: () => provider.loginWithApple(context),
                      style: SignInWithAppleButtonStyle.black,
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Google 로그인'),
                      style: primaryButtonStyle,
                      onPressed: () => provider.loginWithGoogle(context),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
