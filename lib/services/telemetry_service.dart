import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class TelemetryService {
  static const String defaultServerUrl = 'http://192.168.0.103:8080';
  static const String consentKey = 'telemetry_consent';
  static const String serverUrlKey = 'telemetry_server_url';

  static const String lastCrashKey = 'telemetry_last_crash';

  static TelemetryService? _instance;
  static TelemetryService get instance => _instance ??= TelemetryService();

  Future<bool> isConsentGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(consentKey) ?? true;
  }

  Future<void> setConsent(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(consentKey, granted);
    AppLogger.info('Згода на збір діагностики: ${granted ? "УВІМКНЕНО" : "ВИМКНЕНО"}', 'TELEMETRY');
  }

  static Future<Map<String, dynamic>?> getLastLocalCrash() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lastCrashKey);
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearLastLocalCrash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastCrashKey);
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
    final payload = {
      'device': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'appVersion': '1.0.19+20',
      'timestamp': DateTime.now().toIso8601String(),
      'error': error,
      'stackTrace': stack?.toString() ?? '',
      'recentLogs': AppLogger.recentLogs,
      if (extra != null) ...extra,
    };

    // Завжди зберігаємо локальний звіт, щоб користувач міг побачити причину
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastCrashKey, json.encode(payload));
    } catch (_) {}

    if (!await isConsentGranted()) return false;

    try {
      final base = await getServerUrl();
      final url = Uri.parse('$base/api/telemetry/crash-report');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logEvent(String eventName, [Map<String, dynamic>? extra]) async {
    if (!await isConsentGranted()) return;
    try {
      final payload = {
        'device': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'timestamp': DateTime.now().toIso8601String(),
        'event': eventName,
        if (extra != null) ...extra,
      };

      final base = await getServerUrl();
      // Тут можна додати окремий endpoint для івентів, поки що відправляємо як краш для логування
      final url = Uri.parse('$base/api/telemetry/crash-report');

      await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ігноруємо помилки мережі при відправці аналітики
    }
  }

  static const MethodChannel _nativeCrashChannel =
      MethodChannel('com.example.music_flow_mobile/native_crash');

  /// Перевіряє, чи не стався нативний збій Android перед попереднім перезапуском
  static Future<void> checkAndSendPendingNativeCrash() async {
    if (!Platform.isAndroid) return;
    try {
      final pending = await _nativeCrashChannel.invokeMethod<String>('getPendingNativeCrash');
      if (pending != null && pending.isNotEmpty) {
        AppLogger.warning('Знайдено нативний звіт про збій Android! Відправляємо...', 'TELEMETRY');
        final service = TelemetryService.instance;
        final base = await service.getServerUrl();
        final url = Uri.parse('$base/api/telemetry/crash-report');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: pending,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          AppLogger.info('Нативний звіт про збій успішно доставлено на сервер!', 'TELEMETRY');
          await _nativeCrashChannel.invokeMethod('clearPendingNativeCrash');
        }
      }
    } catch (e) {
      AppLogger.warning('Не вдалося перевірити нативний звіт: $e', 'TELEMETRY');
    }
  }

  static void initGlobalCrashHandler() {
    final service = TelemetryService.instance;

    // Перевірка нативних збоїв при запуску
    checkAndSendPendingNativeCrash();

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
