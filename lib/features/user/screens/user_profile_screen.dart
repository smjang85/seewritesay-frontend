import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/features/user/providers/user_profile_provider.dart';
import 'package:see_write_say/core/presentation/theme/text_styles.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider()..initializeProfile(context),
      child: const UserProfileView(),
    );
  }
}

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProfileProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('아바타를 선택하세요', style: kBodyTextStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: provider.avatarList.map((avatar) {
                  final isSelected = provider.selectedAvatar == avatar;
                  return GestureDetector(
                    onTap: () => provider.selectAvatar(avatar),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(avatar),
                      radius: isSelected ? 36 : 30,
                      backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[300],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              const Text('닉네임 입력', style: kBodyTextStyle),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: provider.nicknameController,
                      decoration: const InputDecoration(hintText: '닉네임 입력'),
                      onChanged: (_) => provider.nicknameChecked = false,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => provider.generateRandomNickname(context),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.checkNickname(context),
                    child: const Text('중복 확인'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text('연령대 선택 (선택)', style: kBodyTextStyle),
              const SizedBox(height: 10),
              DropdownButton<AgeGroup>(
                isExpanded: true,
                value: provider.selectedAgeGroup,
                hint: const Text('연령대를 선택해주세요'),
                items: AgeGroup.all.map(
                      (age) => DropdownMenuItem<AgeGroup>(
                    value: age,
                    child: Text(age.label),
                  ),
                ).toList(),
                onChanged: provider.selectAgeGroup,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => provider.submit(context),
                child: Text(provider.isNewUser ? '시작하기' : '저장하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
