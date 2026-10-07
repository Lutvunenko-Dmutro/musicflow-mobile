import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:music_flow_mobile/models/update_info.dart';
import 'package:music_flow_mobile/services/github_update_client.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/services/update_preferences.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

export 'package:music_flow_mobile/models/update_info.dart';

class UpdateService {
  static const String currentVersion = '1.0.32';
  static const int currentBuildNumber = 33;
  static const MethodChannel _installerChannel =
      MethodChannel('com.example.music_flow_mobile/installer');

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

  Future<UpdateInfo?> checkForUpdate({
    String? customServerUrl,
    bool force = false,
    bool allowChannelSwitch = false,
  }) async {
    try {
      final current = await getCurrentVersion();

      // Якщо явно вказано власний сервер розробника — опитуємо його
      if (customServerUrl != null) {
        return await _checkCustomServer(customServerUrl, current, force, allowChannelSwitch);
      }

      // За замовчуванням — швидкий та надійний GitHub Releases API
      final ghInfo = await GithubUpdateClient.instance.checkLatestRelease(
        currentBuildNumber: current.buildNumber,
        currentVersion: current.version,
        force: force,
      );
      if (ghInfo != null) return ghInfo;

      // Якщо на GitHub немає або виникла помилка зв'язку — перевіряємо локальний сервер, якщо налаштовано
      final localServer = await TelemetryService.instance.getServerUrl();
      if (localServer.isNotEmpty && !localServer.contains('0.0.0.0')) {
        return await _checkCustomServer(localServer, current, force, allowChannelSwitch);
      }
    } catch (e) {
      AppLogger.warning('Помилка перевірки оновлень: $e', 'UPDATER');
    }
    return null;
  }

  Future<UpdateInfo?> _checkCustomServer(
    String baseUrl,
    ({String version, int buildNumber}) current,
    bool force,
    bool allowChannelSwitch,
  ) async {
    try {
      final channel = await UpdatePreferences.getChannel();
      final url = Uri.parse(
        '$baseUrl/api/update/check?currentBuild=${current.buildNumber}&channel=${channel.key}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final serverBuild = data['buildNumber'] as int? ?? 0;
        final isDiffChannel = (channel != UpdatePreferences.currentRunningChannel);
        final isNewer = serverBuild > current.buildNumber;
        final isSwitch = (force || allowChannelSwitch) && isDiffChannel && serverBuild >= current.buildNumber;

        if (isNewer || isSwitch || force) {
          return UpdateInfo.fromJson(
            data,
            userCurrentBuild: current.buildNumber,
            isChannelSwitch: isSwitch,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<File> downloadApk(
    UpdateInfo info, {
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
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
      final extDirs = await getExternalCacheDirectories();
      final dir = (extDirs != null && extDirs.isNotEmpty)
          ? extDirs.first
          : await getTemporaryDirectory();
      final apkFile = File('${dir.path}/music_flow_update.apk');
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

      if (info.sha256 != null && info.sha256!.isNotEmpty) {
        final digest = await sha256.bind(apkFile.openRead()).first;
        final actualSha = digest.toString().toLowerCase();
        final expectedSha = info.sha256!.trim().toLowerCase();
        if (actualSha != expectedSha) {
          if (await apkFile.exists()) await apkFile.delete();
          AppLogger.error('Порушення цілісності: SHA-256 $actualSha != $expectedSha', null, null, 'UPDATER');
          throw const FormatException('Помилка безпеки: контрольна сума SHA-256 не збігається. Файл відхилено.');
        }
        AppLogger.success('Контрольну суму SHA-256 підтверджено: $actualSha', 'UPDATER');
      }

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
      AppLogger.warning('Не вдалося показати сповіщення: $e', 'UPDATER');
      return false;
    }
  }
}
