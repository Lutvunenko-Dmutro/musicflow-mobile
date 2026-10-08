import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_flow_mobile/models/update_info.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class UpdateDownloader {
  static Future<File> downloadApk(
    UpdateInfo info, {
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final newStatus = await Permission.storage.request();
        if (!newStatus.isGranted && !newStatus.isLimited) {
          throw Exception('Дозвіл на доступ до сховища відхилено');
        }
      }
    }

    final extDirs = await getExternalCacheDirectories();
    final dir = (extDirs != null && extDirs.isNotEmpty)
        ? extDirs.first
        : await getTemporaryDirectory();
    final apkFile = File('${dir.path}/music_flow_update.apk');

    int retries = 0;
    const maxRetries = 3;
    
    while (retries < maxRetries) {
      try {
        if (await apkFile.exists()) await apkFile.delete();
        await _performDownload(info.downloadUrl, apkFile, info.fileSizeBytes, onProgress);
        
        if (info.sha256 != null && info.sha256!.isNotEmpty) {
          final digest = await sha256.bind(apkFile.openRead()).first;
          final actualSha = digest.toString().toLowerCase();
          final expectedSha = info.sha256!.trim().toLowerCase();
          if (actualSha != expectedSha) {
            if (await apkFile.exists()) await apkFile.delete();
            AppLogger.error('Порушення цілісності: SHA-256 $actualSha != $expectedSha', null, null, 'UPDATER');
            throw const FormatException('Помилка безпеки: контрольна сума SHA-256 не збігається.');
          }
        }

        AppLogger.success('APK успішно завантажено: ${apkFile.path}', 'UPDATER');
        TelemetryService.instance.logEvent('update_downloaded', {
          'version': info.version,
          'buildNumber': info.buildNumber,
          'sizeBytes': info.fileSizeBytes,
        });
        
        return apkFile;
      } on SocketException catch (e) {
        retries++;
        AppLogger.warning('Помилка мережі при завантаженні (Спроба $retries з $maxRetries): $e', 'UPDATER');
        if (retries >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retries));
      }
    }
    throw Exception('Не вдалося завантажити оновлення після $maxRetries спроб');
  }

  static Future<void> _performDownload(
    String url, 
    File file, 
    int fallbackTotal, 
    void Function(double, int, int) onProgress
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.followRedirects = true;
      request.headers['User-Agent'] = 'MusicFlow-Mobile';
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Сервер повернув помилку: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? fallbackTotal;
      final sink = file.openWrite();
      int received = 0;

      await response.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.5;
        onProgress(progress, received, total);
      }).asFuture();

      await sink.close();
    } finally {
      client.close();
    }
  }
}
