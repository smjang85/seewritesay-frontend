import 'package:SeeWriteSay/providers/image/image_list_provider.dart';
import 'package:SeeWriteSay/widgets/app_exit_scope.dart';
import 'package:SeeWriteSay/widgets/common_dropdown.dart';
import 'package:SeeWriteSay/widgets/common_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/widgets/app_drawer_menu.dart';
import 'package:SeeWriteSay/providers/picture/picture_provider.dart';
import 'package:SeeWriteSay/providers/login/login_provider.dart';

class PictureScreen extends StatefulWidget {
  @override
  State<PictureScreen> createState() => _PictureScreenState();
}

class _PictureScreenState extends State<PictureScreen> {
  @override
  void initState() {
    super.initState();

    // 비동기 초기화 로직을 별도 함수로 분리
    Future.microtask(() async {
      final provider = Provider.of<PictureProvider>(context, listen: false);
      final imageListProvider = Provider.of<ImageListProvider>(
        context,
        listen: false,
      );

      await provider.fetchImages();
      imageListProvider.setImages(provider.images);

      await provider.loadUsedImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PictureProvider>();
    final isLoggedIn = context.watch<LoginProvider>().isLoggedIn;
    final image = provider.selectedImage;
    final alreadyUsed = provider.isAlreadyUsed;

    final hasImages = provider.images.isNotEmpty;

    return AppExitScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F8F3),

        appBar: AppBar(
          title: Row(
            children: [SizedBox(width: 8), Text("See Write Say")],
          ),
        ),

        drawer: AppDrawerMenu(
          isLoggedIn: isLoggedIn,
          onLogout: () {
            context.read<LoginProvider>().logout(context);
          },
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child:
              hasImages
                  ? Column(
                    children: [
                      Text(
                        "이 장면을 보고 영어로 이야기해보세요",
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: _buildImageSection(image, alreadyUsed, provider),
                      ),
                      SizedBox(height: 20),
                      _buildActionButtons(image, provider),
                    ],
                  )
                  : Center(
                    child: Text(
                      "조회된 이미지가 없습니다.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
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
          height: 380, // 크게!
          borderRadius: 16, // 더 둥글게 하고 싶으면 늘려도 됨
        )
        : const Center(child: Icon(Icons.image_not_supported));
  }

  Widget _buildActionButtons(image, PictureProvider provider) {
    final categories = provider.categories;
    final selectedCategory = provider.selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔁 다른 그림 아이콘 버튼 (중앙 정렬)
        Center(
          child: IconButton(
            onPressed: provider.loadNextImage,
            icon: const Icon(Icons.refresh, size: 28),
            tooltip: "다른 그림 보기",
          ),
        ),

        const SizedBox(height: 8), // 새로고침 버튼 아래 간격도 줄임
        // 🎯 유형 선택 드롭다운 (이미지 폭과 맞춤)
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

        // 📝 작문 & 리딩 버튼 한 줄 정렬, 폭 맞춤
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
                        imageModel: provider.selectedImage!,
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