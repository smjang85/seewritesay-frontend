import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/services/api/image/image_api_service.dart';

class PictureScreen extends StatefulWidget {
  @override
  State<PictureScreen> createState() => _PictureScreenState();
}

class _PictureScreenState extends State<PictureScreen> {
  List<ImageModel> _images = [];
  final Set<String> _usedImagePaths = {};
  ImageModel? selectedImage;
  bool _imageLoadSuccess = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final images = await ImageApiService.fetchAllImages();
      print("✅ 서버에서 받아온 이미지 개수: ${images.length}");

      setState(() {
        _images = images;
        _loadRandomImage();
      });
    } catch (e) {
      print("❌ 이미지 불러오기 실패: $e");
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('writingHistory') ?? [];

    final used = history
        .map((e) => jsonDecode(e)['image'] as String?)
        .whereType<String>()
        .toSet();

    _usedImagePaths
      ..clear()
      ..addAll(used);
  }

  void _loadRandomImage() {
    if (_images.isEmpty) {
      setState(() {
        selectedImage = null;
      });
      return;
    }

    final unusedImages =
    _images.where((image) => !_usedImagePaths.contains(image.path)).toList();
    final useUnused = unusedImages.isNotEmpty && Random().nextDouble() < 0.7;

    final image = useUnused
        ? unusedImages[Random().nextInt(unusedImages.length)]
        : _images[Random().nextInt(_images.length)];

    print("📸 선택된 이미지 path: ${image.path}");

    setState(() {
      selectedImage = image;
      _imageLoadSuccess = true;
    });
  }

  void _goToWritingScreen() {
    if (selectedImage == null || !_imageLoadSuccess) return;
    context.pushNamed('writing', extra: selectedImage);
  }

  @override
  Widget build(BuildContext context) {
    final alreadyUsed = selectedImage != null &&
        _usedImagePaths.contains(selectedImage!.path);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      appBar: AppBar(title: Text("See Write Say")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_circle, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text("로그인", style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit_note),
              title: Text("진행한 작문"),
              onTap: () => context.pushNamed('history'),
            ),
            ListTile(
              leading: Icon(Icons.record_voice_over),
              title: Text("녹음한 리딩"),
              onTap: () {}, // TODO
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text("유형 선택 (랜덤 / 학교 / 여행)"),
              onTap: () {}, // TODO
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          children: [
            Text("이 장면을 보고 영어로 이야기해보세요", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: selectedImage != null
                        ? Image.network(
                      '${ApiConstants.baseUrl}${selectedImage!.path}',
                      height: 400,
                      errorBuilder: (context, error, stackTrace) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _imageLoadSuccess = false;
                          });
                        });
                        return Icon(Icons.broken_image, size: 100, color: Colors.grey);
                      },
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("사용할 수 있는 이미지가 없습니다", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (alreadyUsed)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(Icons.check_circle, color: Colors.green, size: 30),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (selectedImage == null || _images.isEmpty)
              IconButton(
                icon: Icon(Icons.refresh, size: 40, color: Colors.orange),
                onPressed: _fetchImages,
                tooltip: "새로고침",
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadRandomImage,
                    icon: Icon(Icons.refresh),
                    label: Text("다른 그림 보기"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (_imageLoadSuccess)
                    ElevatedButton(
                      onPressed: _goToWritingScreen,
                      child: Text("작문하러 가기"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
