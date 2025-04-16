import 'package:intl/intl.dart';

class FormatHelper {
  static String extractRecordingTimestamp(String fileName) {
    try {
      final baseName = fileName.trim().split('/').last;
      final nameWithoutExt = baseName.split('.').first;
      final parts = nameWithoutExt.split('_');
      if (parts.length < 2) return fileName;

      final date = parts[parts.length - 2];
      final timeRaw = parts[parts.length - 1];

      if (date.length != 8 || timeRaw.length != 6) return fileName;

      return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)} '
          '${timeRaw.substring(0, 2)}:${timeRaw.substring(2, 4)}:${timeRaw.substring(4, 6)}';
    } catch (_) {
      return fileName;
    }
  }

  static String formatReadableTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
