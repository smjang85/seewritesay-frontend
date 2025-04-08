import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/widgets/app_drawer_menu.dart';
import 'package:SeeWriteSay/providers/picture/picture_provider.dart';
import 'package:SeeWriteSay/providers/login/login_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PictureScreen extends StatefulWidget {
  @override
  State<PictureScreen> createState() => _PictureScreenState();
}

class _PictureScreenState extends State<PictureScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<PictureProvider>();
    provider.loadUsedImages();
    provider.fetchImages();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PictureProvider>();
    final isLoggedIn = context.watch<LoginProvider>().isLoggedIn;
    final image = provider.selectedImage;
    final alreadyUsed = provider.isAlreadyUsed;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      appBar: AppBar(title: Text("See Write Say")),
      drawer: AppDrawerMenu(
        isLoggedIn: isLoggedIn,
        onLogout: () {
          context.read<LoginProvider>().logout(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          children: [
            Text("이 장면을 보고 영어로 이야기해보세요", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Expanded(child: _buildImageSection(image, alreadyUsed, provider)),
            SizedBox(height: 20),
            _buildActionButtons(image, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(image, bool alreadyUsed, PictureProvider provider) {
    return Stack(
      children: [
        Center(
          child:
              image != null
                  ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.baseUrl}${image.path}',
                    height: 400,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        provider.setImageLoadSuccess(false);
                      });
                      return const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.grey,
                      );
                    },
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "사용할 수 있는 이미지가 없습니다",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
        ),
        if (alreadyUsed)
          const Positioned(
            right: 10,
            top: 10,
            child: Icon(Icons.check_circle, color: Colors.green, size: 30),
          ),
      ],
    );
  }

  Widget _buildActionButtons(image, PictureProvider provider) {
    if (image == null || provider.images.isEmpty) {
      return IconButton(
        icon: Icon(Icons.refresh, size: 40, color: Colors.orange),
        onPressed: provider.fetchImages,
        tooltip: "새로고침",
      );
    } else {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: provider.loadRandomImage,
            icon: Icon(Icons.refresh),
            label: Text("다른 그림 보기"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
          ),
          SizedBox(height: 10),
          if (provider.imageLoadSuccess)
            ElevatedButton(
              onPressed: () {
                if (provider.selectedImage != null &&
                    provider.imageLoadSuccess) {
                  NavigationHelpers.goToWritingScreen(
                    context,
                    provider.selectedImage!,
                  );
                }
              },
              child: Text("작문하러 가기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      );
    }
  }
}
