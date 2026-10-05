import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:music_flow_mobile/models/release_history_item.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final String downloadUrl;
  final int fileSizeBytes;
  final List<ReleaseHistoryItem> history;
  final int userCurrentBuild;

  const UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    required this.downloadUrl,
    required this.fileSizeBytes,
    this.history = const [],
    this.userCurrentBuild = 0,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json, {int userCurrentBuild = 0}) {
    final rawHistory = json['history'] as List<dynamic>?;
    final historyList = rawHistory != null
        ? rawHistory
            .whereType<Map<String, dynamic>>()
            .map(ReleaseHistoryItem.fromJson)
            .toList()
        : <ReleaseHistoryItem>[];

    return UpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['buildNumber'] as int? ?? 1,
      changelog: json['changelog'] as String? ?? 'Оновлення без опису',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      history: historyList,
      userCurrentBuild: userCurrentBuild,
    );
  }

  List<ReleaseHistoryItem> get missedReleases {
    if (history.isEmpty) return const [];
    return history.where((h) => h.buildNumber > userCurrentBuild).toList();
  }
}

class UpdateService {
  static const String currentVersion = '1.0.1';
  static const int currentBuildNumber = 2;
  static const MethodChannel _installerChannel = MethodChannel('com.example.music_flow_mobile/installer');

  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService();

  Future<({String version, int buildNumber})> getCurrentVersion() async {
    try {
      final res = await _installerChannel.invokeMapMethod<String, dynamic>('getAppVersion');
      if (res != null) {
        final name = res['versionName'] as String? ?? currentVersion;
        final code = (res['versionCode'] as num?)?.toInt() ?? currentBuildNumber;
        return (version: name, buildNumber: code);
      }
    } catch (_) {}
    return (version: currentVersion, buildNumber: currentBuildNumber);
  }

  Future<UpdateInfo?> checkForUpdate({String? customServerUrl}) async {
    try {
      final current = await getCurrentVersion();
      final base = customServerUrl ?? await TelemetryService.instance.getServerUrl();
      final url = Uri.parse('$base/api/update/check?currentBuild=${current.buildNumber}');
      AppLogger.info('Перевірка оновлень на $url', 'UPDATER');

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final info = UpdateInfo.fromJson(data, userCurrentBuild: current.buildNumber);

        if (info.buildNumber > current.buildNumber) {
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

  Future<bool> showSystemNotification({
    required String title,
    required String message,
  }) async {
    try {
      final result = await _installerChannel.invokeMethod<bool>('showUpdateNotification', {
        'title': title,
        'message': message,
      });
      return result ?? false;
    } catch (e) {
      AppLogger.warning('Не вдалося показати системне сповіщення: $e', 'UPDATER');
      return false;
    }
  }
}
