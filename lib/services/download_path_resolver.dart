import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class DownloadPathResolver {
  static Future<String> getMusicDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('download_path');
    
    if (customPath != null &&
        customPath.isNotEmpty &&
        customPath != 'За замовчуванням (Внутрішня пам\'ять)') {
      final customDir = Directory(customPath);
      if (customDir.existsSync()) return customPath;
    }

    const defaultPath = '/storage/emulated/0/Music';
    final defaultDir = Directory(defaultPath);
    if (defaultDir.existsSync()) {
      return defaultPath;
    }

    if (Platform.isAndroid) {
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
        if (extDirs != null && extDirs.isNotEmpty) {
          return extDirs.first.path;
        }
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final musicDir = Directory(p.join(extDir.path, 'Music'));
          if (!musicDir.existsSync()) musicDir.createSync(recursive: true);
          return musicDir.path;
        }
      } catch (e) {
        AppLogger.warning('Не вдалося отримати external music storage: $e', 'DOWNLOAD');
      }
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory(p.join(docsDir.path, 'Music'));
    if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
    return fallbackDir.path;
  }
}
