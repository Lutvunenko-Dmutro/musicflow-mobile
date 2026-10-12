import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/services/update_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class UpdateDownloader {
  static Future<File> downloadApk(
    UpdateInfo info, {
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    final extDirs = await getExternalCacheDirectories();
    final dir = (extDirs != null && extDirs.isNotEmpty)
        ? extDirs.first
        : await getTemporaryDirectory();
    final apkFile = File('${dir.path}/music_flow_update.apk');

    int retries = 0;
    const maxRetries = 3;

    UpdateService.instance.showDownloadProgressNotification(
      title: 'MusicFlow • Оновлення v${info.version}',
      message: 'Підготовка до завантаження...',
      progress: 0,
      indeterminate: true,
    );

    while (retries < maxRetries) {
      try {
        if (await apkFile.exists()) await apkFile.delete();
        await _performDownload(info, apkFile, onProgress);

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

        UpdateService.instance.showDownloadCompleteNotification(
          title: 'Оновлення завантажено',
          message: 'Натисніть для встановлення v${info.version}',
          filePath: apkFile.path,
        );

        return apkFile;
      } on SocketException catch (e) {
        retries++;
        AppLogger.warning('Помилка мережі (Спроба $retries з $maxRetries): $e', 'UPDATER');
        if (retries >= maxRetries) {
          UpdateService.instance.cancelDownloadNotification();
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * retries));
      } catch (_) {
        UpdateService.instance.cancelDownloadNotification();
        rethrow;
      }
    }
    UpdateService.instance.cancelDownloadNotification();
    throw Exception('Не вдалося завантажити оновлення після $maxRetries спроб');
  }

  static Future<void> _performDownload(
    UpdateInfo info,
    File file,
    void Function(double, int, int) onProgress,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(info.downloadUrl));
      request.followRedirects = true;
      request.headers['User-Agent'] = 'MusicFlow-Mobile';
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Сервер повернув помилку: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? info.fileSizeBytes;
      final sink = file.openWrite();
      int received = 0;
      int lastNotificationTime = 0;
      int lastReportedPercent = -1;

      await response.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.5;
        onProgress(progress, received, total);

        final percent = (progress * 100).toInt();
        final now = DateTime.now().millisecondsSinceEpoch;
        if (percent > lastReportedPercent && (now - lastNotificationTime > 300 || percent == 100)) {
          lastNotificationTime = now;
          lastReportedPercent = percent;
          final recMb = (received / 1048576).toStringAsFixed(1);
          final totMb = total > 0 ? (total / 1048576).toStringAsFixed(1) : '?';
          UpdateService.instance.showDownloadProgressNotification(
            title: 'MusicFlow • Оновлення v${info.version}',
            message: '$recMb MB / $totMb MB ($percent%)',
            progress: percent,
          );
        }
      }).asFuture();

      await sink.close();
    } finally {
      client.close();
    }
  }
}
