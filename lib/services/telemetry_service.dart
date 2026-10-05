import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class TelemetryService {
  static const String defaultServerUrl = 'http://192.168.0.103:8080';
  static const String consentKey = 'telemetry_consent';
  static const String serverUrlKey = 'telemetry_server_url';

  static TelemetryService? _instance;
  static TelemetryService get instance => _instance ??= TelemetryService();

  Future<bool> isConsentGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(consentKey) ?? false;
  }

  Future<void> setConsent(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(consentKey, granted);
    AppLogger.info('Згода на збір діагностики: ${granted ? "УВІМКНЕНО" : "ВИМКНЕНО"}', 'TELEMETRY');
  }

  Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(serverUrlKey) ?? defaultServerUrl;
  }

  Future<void> setServerUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverUrlKey, cleanUrl);
    AppLogger.info('Адресу сервера телеметрії змінено на: $cleanUrl', 'TELEMETRY');
  }

  Future<bool> checkServerHealth() async {
    try {
      final base = await getServerUrl();
      final url = Uri.parse('$base/api/health');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendCrashReport({
    required String error,
    StackTrace? stack,
    Map<String, dynamic>? extra,
  }) async {
    if (!await isConsentGranted()) return false;

    try {
      final base = await getServerUrl();
      final url = Uri.parse('$base/api/telemetry/crash-report');
      final device = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

      final payload = {
        'device': device,
        'appVersion': '1.0.0+1',
        'timestamp': DateTime.now().toIso8601String(),
        'error': error,
        'stackTrace': stack?.toString() ?? '',
        'recentLogs': AppLogger.recentLogs,
        if (extra != null) ...extra,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      // Тихо ігноруємо помилки мережі, щоб не порушувати роботу плеєра
      return false;
    }
  }

  static void initGlobalCrashHandler() {
    final service = TelemetryService.instance;

    AppLogger.onErrorListener = (msg, ex, stack, tag) {
      service.sendCrashReport(
        error: '$msg ${ex != null ? "($ex)" : ""}',
        stack: stack,
        extra: {'source': 'AppLogger', 'tag': tag ?? 'GENERAL'},
      );
    };

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      service.sendCrashReport(
        error: details.exceptionAsString(),
        stack: details.stack,
        extra: {'source': 'FlutterError'},
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      service.sendCrashReport(
        error: error.toString(),
        stack: stack,
        extra: {'source': 'PlatformDispatcher'},
      );
      return true;
    };
  }
}
