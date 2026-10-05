import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final String downloadUrl;
  final int fileSizeBytes;

  const UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    required this.downloadUrl,
    required this.fileSizeBytes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['buildNumber'] as int? ?? 1,
      changelog: json['changelog'] as String? ?? 'Оновлення без опису',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    );
  }
}

class UpdateService {
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 1;
  static const MethodChannel _installerChannel = MethodChannel('com.example.music_flow_mobile/installer');

  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService();

  Future<UpdateInfo?> checkForUpdate({String? customServerUrl}) async {
    try {
      final base = customServerUrl ?? await TelemetryService.instance.getServerUrl();
      final url = Uri.parse('$base/api/update/check');
      AppLogger.info('Перевірка оновлень на $url', 'UPDATER');

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final info = UpdateInfo.fromJson(data);

        // Якщо збірка на сервері новіша або номер версії відрізняється у більший бік
        if (info.buildNumber > currentBuildNumber || info.version != currentVersion) {
          AppLogger.success('Знайдено оновлення v${info.version}+${info.buildNumber}', 'UPDATER');
          return info;
        }
      }
    } catch (e) {
      AppLogger.warning('Не вдалося перевірити оновлення: $e', 'UPDATER');
    }
    return null;
  }

  Future<File> downloadApk(
    UpdateInfo info, {
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(info.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Сервер повернув помилку: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? info.fileSizeBytes;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/music_flow_update.apk');
      if (await apkFile.exists()) await apkFile.delete();

      final sink = apkFile.openWrite();
      int received = 0;

      await response.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.5;
        onProgress(progress, received, total);
      }).asFuture();

      await sink.close();
      AppLogger.success('APK успішно завантажено: ${apkFile.path}', 'UPDATER');
      return apkFile;
    } finally {
      client.close();
    }
  }

  Future<bool> installApk(File apkFile) async {
    try {
      AppLogger.info('Запуск встановлення APK: ${apkFile.path}', 'UPDATER');
      final result = await _installerChannel.invokeMethod<bool>('installApk', {
        'filePath': apkFile.path,
      });
      return result ?? false;
    } catch (e, stack) {
      AppLogger.error('Помилка відкриття інсталятора APK', e, stack, 'UPDATER');
      return false;
    }
  }
}
