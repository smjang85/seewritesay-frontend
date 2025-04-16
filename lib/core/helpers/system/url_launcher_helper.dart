import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("❌ URL 실행 실패: $url");
    }
  }
}
