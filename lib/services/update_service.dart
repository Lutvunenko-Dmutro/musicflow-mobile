import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:music_flow_mobile/models/update_info.dart';
import 'package:music_flow_mobile/services/github_update_client.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/services/update_preferences.dart';
import 'package:music_flow_mobile/services/update_downloader.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

export 'package:music_flow_mobile/models/update_info.dart';

class UpdateService {
  static const MethodChannel _installerChannel =
      MethodChannel('com.example.music_flow_mobile/installer');

  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService();

  Future<({String version, int buildNumber})> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return (
        version: packageInfo.version,
        buildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
      );
    } catch (_) {
      // Fallback на виклик Platform Channel, якщо package_info_plus недоступний у тестах
      try {
        final res = await _installerChannel.invokeMapMethod<String, dynamic>('getAppVersion');
        if (res != null) {
          final name = res['versionName'] as String? ?? '1.0.0';
          final code = (res['versionCode'] as num?)?.toInt() ?? 0;
          return (version: name, buildNumber: code);
        }
      } catch (_) {}
      return (version: '1.0.0', buildNumber: 0);
    }
  }

  Future<UpdateInfo?> checkForUpdate({
    String? customServerUrl,
    bool force = false,
    bool allowChannelSwitch = false,
  }) async {
    final current = await getCurrentVersion();
    
    // Створюємо список спроб (Fallbacks)
    final attempts = <Future<UpdateInfo?> Function()>[];

    if (customServerUrl != null) {
      attempts.add(() => _checkCustomServer(customServerUrl, current, force, allowChannelSwitch));
    } else {
      attempts.add(() => GithubUpdateClient.instance.checkLatestRelease(
            currentBuildNumber: current.buildNumber,
            currentVersion: current.version,
            force: force,
          ));
          
      attempts.add(() async {
        final localServer = await TelemetryService.instance.getServerUrl();
        if (localServer.isNotEmpty && !localServer.contains('0.0.0.0')) {
          return _checkCustomServer(localServer, current, force, allowChannelSwitch);
        }
        return null;
      });
    }

    for (final attempt in attempts) {
      try {
        final result = await attempt();
        if (result != null) return result;
      } catch (e) {
        AppLogger.warning('Спроба пошуку оновлень завершилась помилкою: $e', 'UPDATER');
      }
    }
    
    AppLogger.info('Оновлень не знайдено на жодному доступному сервері.', 'UPDATER');
    return null;
  }

  Future<UpdateInfo?> _checkCustomServer(
    String baseUrl,
    ({String version, int buildNumber}) current,
    bool force,
    bool allowChannelSwitch,
  ) async {
    final channel = await UpdatePreferences.getChannel();
    final url = Uri.parse(
      '$baseUrl/api/update/check?currentBuild=${current.buildNumber}&channel=${channel.key}',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 4));
    
    if (response.statusCode == 429) {
      AppLogger.warning('Забагато запитів до сервера оновлень (HTTP 429). Спробуйте пізніше.', 'UPDATER');
      return null;
    }
    
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
    return null;
  }

  Future<File> downloadApk(
    UpdateInfo info, {
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    return UpdateDownloader.downloadApk(info, onProgress: onProgress);
  }

  Future<bool> installApk(File apkFile, UpdateInfo info) async {
    try {
      final current = await getCurrentVersion();
      
      // Валідація версії перед інсталяцією (Anti-Downgrade)
      if (!info.isChannelSwitch && info.buildNumber < current.buildNumber) {
        AppLogger.warning(
          'Відхилено спробу встановити старішу версію: ${info.buildNumber} < ${current.buildNumber}', 
          'UPDATER'
        );
        return false;
      }

      AppLogger.info('Запуск встановлення APK: ${apkFile.path}', 'UPDATER');
      final result = await _installerChannel.invokeMethod<bool>('installApk', {
        'filePath': apkFile.path,
      });
      
      if (result == true) {
        TelemetryService.instance.logEvent('update_installed', {
          'version': info.version,
          'buildNumber': info.buildNumber,
        });
      }
      return result ?? false;
    } catch (e, stack) {
      AppLogger.error('Помилка відкриття інсталятора APK', e, stack, 'UPDATER');
      TelemetryService.instance.logEvent('update_install_failed', {
        'version': info.version,
        'error': e.toString(),
      });
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
