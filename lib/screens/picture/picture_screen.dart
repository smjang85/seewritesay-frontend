import 'package:SeeWriteSay/providers/image/image_list_provider.dart';
import 'package:SeeWriteSay/services/logic/common/session_manager.dart';
import 'package:SeeWriteSay/widgets/app_exit_scope.dart';
import 'package:SeeWriteSay/widgets/common_dropdown.dart';
import 'package:SeeWriteSay/widgets/common_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/widgets/app_drawer_menu.dart';
import 'package:SeeWriteSay/providers/picture/picture_provider.dart';
import 'package:SeeWriteSay/providers/login/login_provider.dart';
import 'package:SeeWriteSay/services/api/user/user_api_service.dart';

class PictureScreen extends StatefulWidget {
  @override
  State<PictureScreen> createState() => _PictureScreenState();
}

class _PictureScreenState extends State<PictureScreen> {
  String? nickname;
  String? avatar;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    final provider = Provider.of<PictureProvider>(context, listen: false);
    final imageListProvider = Provider.of<ImageListProvider>(context, listen: false);

    await provider.fetchImages();
    imageListProvider.setImages(provider.images);
    await provider.loadUsedImages();

    final sessionManager = context.read<SessionManager>();
    sessionManager.startSessionTimer(context);

    try {
      final profile = await UserApiService.getCurrentUserProfile();
      setState(() {
        nickname = profile.nickname;
        avatar = profile.avatar != null ? '${profile.avatar}' : null;
      });
    } catch (e) {
      debugPrint('❌ 사용자 프로필 조회 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PictureProvider>();
    final isLoggedIn = context.watch<LoginProvider>().isLoggedIn;
    final image = provider.selectedImage;
    final alreadyUsed = provider.isAlreadyUsed;

    return AppExitScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F8F3),
        appBar: AppBar(
          title: Row(children: [SizedBox(width: 8), Text("See Write Say")]),
        ),
        drawer: AppDrawerMenu(
          isLoggedIn: isLoggedIn,
          nickname: nickname,
          avatar: avatar,
          onLogout: () {
            context.read<LoginProvider>().logout(context);
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await provider.fetchImages();
            context.read<ImageListProvider>().setImages(provider.images);
            await provider.loadUsedImages();
          },
          child: provider.images.isNotEmpty
              ? ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            children: [
              const Text(
                "이 장면을 보고 영어로 이야기해보세요",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 380,
                child: _buildImageSection(image, alreadyUsed, provider),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(image, provider),
            ],
          )
              : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 200),
              Center(
                child: Text(
                  "조회된 이미지가 없습니다.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(image, bool alreadyUsed, PictureProvider provider) {
    return image != null
        ? CommonImageViewer(
      imagePath: image.path,
      showCheck: alreadyUsed,
      height: 380,
      borderRadius: 16,
    )
        : const Center(child: Icon(Icons.image_not_supported));
  }

  Widget _buildActionButtons(image, PictureProvider provider) {
    final categories = provider.categories;
    final selectedCategory = provider.selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: IconButton(
            onPressed: provider.loadNextImage,
            icon: const Icon(Icons.refresh, size: 28),
            tooltip: "다른 그림 보기",
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 380,
          child: CommonDropdown(
            value: selectedCategory,
            items: categories,
            label: "유형",
            onChanged: (value) {
              if (value != null) {
                provider.setSelectedCategory(value);
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        if (provider.imageLoadSuccess)
          SizedBox(
            width: 380,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (provider.selectedImage != null) {
                      NavigationHelpers.goToWritingScreen(
                        context,
                        provider.selectedImage!,
                      );
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("작문하러 가기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (provider.selectedImage != null) {
                      NavigationHelpers.goToReadingScreen(
                        context,
                        imageDto: provider.selectedImage!,
                      );
                    }
                  },
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text("리딩하러 가기"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}