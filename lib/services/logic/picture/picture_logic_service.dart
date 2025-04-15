import 'dart:math';
import 'package:SeeWriteSay/dto/image_dto.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';

class PictureLogicService {
  static Future<Set<String>> loadUsedImagePaths() async {
    final prefs = await CommonLogicService.prefs();
    final history = prefs.getStringList('writingHistory') ?? [];

    return history
        .map((e) => CommonLogicService.decodeJson(e)['image'] as String?)
        .whereType<String>()
        .toSet();
  }

  static ImageDto pickRandomImage(List<ImageDto> all, Set<String> used) {
    if (all.isEmpty) throw Exception("이미지 없음");

    final unused = all.where((img) => !used.contains(img.path)).toList();
    final useUnused = unused.isNotEmpty && Random().nextDouble() < 0.7;

    return useUnused
        ? unused[Random().nextInt(unused.length)]
        : all[Random().nextInt(all.length)];
  }
}