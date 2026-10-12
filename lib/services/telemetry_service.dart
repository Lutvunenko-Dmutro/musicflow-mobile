import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/native_crash_handler.dart';
import 'package:music_flow_mobile/services/server_discovery_service.dart';
import 'package:music_flow_mobile/services/telemetry_crash_storage.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class TelemetryService {
  static const String defaultServerUrl = String.fromEnvironment(
    'DEV_SERVER_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String consentKey = 'telemetry_consent';
  static const String serverUrlKey = 'telemetry_server_url';
  static const String lastCrashKey = TelemetryCrashStorage.lastCrashKey;

  static TelemetryService? _instance;
  static TelemetryService get instance => _instance ??= TelemetryService();
  static String? _cachedVersion;
  static DateTime? _rateLimitedUntil;
  static bool get isRateLimited =>
      _rateLimitedUntil != null && DateTime.now().isBefore(_rateLimitedUntil!);

  static void _check429(int code) {
    if (code == 429) _rateLimitedUntil = DateTime.now().add(const Duration(seconds: 60));
  }

  Future<String> getAppVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedVersion = '${info.version}+${info.buildNumber}';
      return _cachedVersion!;
    } catch (_) {
      return '0.1.12+13';
    }
  }

  Timer? _heartbeatTimer;
  AppLifecycleListener? _lifecycleListener;
  String _currentLifecycleState = 'in_app';

  Future<bool> isConsentGranted() async =>
      (await SharedPreferences.getInstance()).getBool(consentKey) ?? true;

  Future<void> setConsent(bool granted) async {
    (await SharedPreferences.getInstance()).setBool(consentKey, granted);
    AppLogger.info('Згода на збір діагностики: ${granted ? "УВІМКНЕНО" : "ВИМКНЕНО"}', 'TELEMETRY');
  }

  static Future<Map<String, dynamic>?> getLastLocalCrash() => TelemetryCrashStorage.getLastLocalCrash();
  static Future<void> clearLastLocalCrash() => TelemetryCrashStorage.clearLastLocalCrash();

  Future<String> getServerUrl() async =>
      (await SharedPreferences.getInstance()).getString(serverUrlKey) ?? defaultServerUrl;

  Future<void> setServerUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    (await SharedPreferences.getInstance()).setString(serverUrlKey, cleanUrl);
    AppLogger.info('Адресу сервера телеметрії змінено на: $cleanUrl', 'TELEMETRY');
  }

  Future<bool> checkServerHealth() async {
    try {
      final base = await getServerUrl();
      final dev = Uri.encodeComponent('${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      final ver = await getAppVersion();
      final url = Uri.parse('$base/api/telemetry/ping?device=$dev&version=$ver');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _lifecycleListener?.dispose();
    _currentLifecycleState = 'in_app';

    _lifecycleListener = AppLifecycleListener(
      onResume: () => sendHeartbeat(state: _currentLifecycleState = 'in_app'),
      onPause: () => sendHeartbeat(state: _currentLifecycleState = 'background'),
      onDetach: () => sendHeartbeat(state: _currentLifecycleState = 'closed'),
    );

    sendHeartbeat(state: 'in_app');
    _tryAutoDiscovery();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_currentLifecycleState == 'in_app') {
        sendHeartbeat(state: 'in_app');
      }
    });
  }

  void _tryAutoDiscovery() {
    ServerDiscoveryService.discoverLocalServer().then((discovered) async {
      if (discovered != null && !isRateLimited) {
        final current = await getServerUrl();
        if (current == defaultServerUrl || current.contains('localhost')) {
          await setServerUrl(discovered);
          sendHeartbeat(state: _currentLifecycleState);
        }
      }
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
    if (isRateLimited) return;
    try {
      final base = await getServerUrl();
      final ver = await getAppVersion();
      final payload = {
        'device': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'appVersion': ver,
        'state': state,
        'screen': screen ?? 'MusicFlow App',
        'timestamp': DateTime.now().toIso8601String(),
      };
      final res = await http.post(
        Uri.parse('$base/api/telemetry/heartbeat'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
      _check429(res.statusCode);
    } catch (_) {}
  }

  Future<bool> sendCrashReport({required String error, StackTrace? stack, Map<String, dynamic>? extra}) async {
    final ver = await getAppVersion();
    final payload = {
      'device': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'appVersion': ver,
      'timestamp': DateTime.now().toIso8601String(),
      'error': error,
      'stackTrace': stack?.toString() ?? '',
      'recentLogs': AppLogger.recentLogs,
      if (extra != null) ...extra,
    };

    await TelemetryCrashStorage.saveLocalCrash(payload);
    if (!await isConsentGranted() || isRateLimited) return false;

    try {
      final base = await getServerUrl();
      final res = await http.post(
        Uri.parse('$base/api/telemetry/crash-report'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 5));
      _check429(res.statusCode);
      if (res.statusCode == 200) await clearLastLocalCrash();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> retryPendingCrashReport() async {
    if (isRateLimited || !await isConsentGranted()) return;
    final base = await getServerUrl();
    await TelemetryCrashStorage.retryPendingCrash(base, _check429);
  }

  Future<void> logEvent(String eventName, [Map<String, dynamic>? extra]) async {
    if (!await isConsentGranted() || isRateLimited) return;
    try {
      final payload = {
        'device': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'timestamp': DateTime.now().toIso8601String(),
        'event': eventName,
        if (extra != null) ...extra,
      };
      final base = await getServerUrl();
      final res = await http.post(
        Uri.parse('$base/api/telemetry/events'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
      _check429(res.statusCode);
    } catch (_) {}
  }

  static void initGlobalCrashHandler() => NativeCrashHandler.init();
}
