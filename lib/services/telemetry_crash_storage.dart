import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TelemetryCrashStorage {
  static const String lastCrashKey = 'telemetry_last_crash';

  static Future<void> saveLocalCrash(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastCrashKey, json.encode(payload));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getLastLocalCrash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(lastCrashKey);
      if (raw == null) return null;
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearLastLocalCrash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(lastCrashKey);
    } catch (_) {}
  }

  static Future<void> retryPendingCrash(String base, void Function(int) check429) async {
    final lastCrash = await getLastLocalCrash();
    if (lastCrash == null) return;
    try {
      final res = await http.post(
        Uri.parse('$base/api/telemetry/crash-report'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode(lastCrash),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) await clearLastLocalCrash();
      check429(res.statusCode);
    } catch (_) {}
  }
}
