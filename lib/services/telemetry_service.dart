import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/native_crash_handler.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class TelemetryService {
  static const String defaultServerUrl = 'http://192.168.0.229:8080';
  static const String consentKey = 'telemetry_consent';
  static const String serverUrlKey = 'telemetry_server_url';
  static const String lastCrashKey = 'telemetry_last_crash';

  static TelemetryService? _instance;
  static TelemetryService get instance => _instance ??= TelemetryService();

  Timer? _heartbeatTimer;
  AppLifecycleListener? _lifecycleListener;

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
      final dev = Uri.encodeComponent('${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      final url = Uri.parse('$base/api/telemetry/ping?device=$dev&version=1.0.19+20');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _lifecycleListener?.dispose();

    _lifecycleListener = AppLifecycleListener(
      onResume: () => sendHeartbeat(state: 'in_app'),
      onPause: () => sendHeartbeat(state: 'background'),
      onDetach: () => sendHeartbeat(state: 'closed'),
    );

    sendHeartbeat(state: 'in_app');
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      sendHeartbeat(state: 'in_app');
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    sendHeartbeat(state: 'closed');
  }

  Future<void> sendHeartbeat({String state = 'in_app', String? screen}) async {
    try {
      final base = await getServerUrl();
      final url = Uri.parse('$base/api/telemetry/heartbeat');
      final payload = {
        'device': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'appVersion': '1.0.19+20',
        'state': state,
        'screen': screen ?? 'MusicFlow App',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
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
    } catch (_) {
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
      final url = Uri.parse('$base/api/telemetry/events');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static void initGlobalCrashHandler() => NativeCrashHandler.init();
}
