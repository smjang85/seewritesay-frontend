import 'dart:math';
import 'package:see_write_say/core/data/shared_prefs_service.dart';
import 'package:see_write_say/core/data/json_helper.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';


class PictureLogicService {
  static Future<Set<String>> loadUsedImagePaths() async {
    final history = await StorageService.getStringList('writingHistory');

    return history
        .map((e) => JsonHelper.decode(e)['image'] as String?)
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