import 'package:shared_preferences/shared_preferences.dart';

enum UpdateFrequency {
  onLaunch('on_launch', 'При кожному запуску'),
  daily('daily', 'Раз на день'),
  weekly('weekly', 'Раз на тиждень'),
  manual('manual', 'Лише вручну');

  final String key;
  final String label;
  const UpdateFrequency(this.key, this.label);

  static UpdateFrequency fromKey(String? key) {
    return UpdateFrequency.values.firstWhere(
      (e) => e.key == key,
      orElse: () => UpdateFrequency.onLaunch,
    );
  }
}

class UpdatePreferences {
  static const _keyAutoCheck = 'update_auto_check';
  static const _keyFrequency = 'update_frequency';
  static const _keySystemNotif = 'update_system_notif';
  static const _keyLastCheck = 'update_last_check_ms';

  static Future<bool> isAutoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoCheck) ?? true;
  }

  static Future<void> setAutoCheckEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCheck, enabled);
  }

  static Future<UpdateFrequency> getFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFrequency);
    return UpdateFrequency.fromKey(raw);
  }

  static Future<void> setFrequency(UpdateFrequency frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFrequency, frequency.key);
  }

  static Future<bool> isSystemNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySystemNotif) ?? true;
  }

  static Future<void> setSystemNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySystemNotif, enabled);
  }

  static Future<bool> shouldCheckNow() async {
    final auto = await isAutoCheckEnabled();
    if (!auto) return false;

    final freq = await getFrequency();
    if (freq == UpdateFrequency.manual) return false;
    if (freq == UpdateFrequency.onLaunch) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastCheckMs = prefs.getInt(_keyLastCheck) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMs = now - lastCheckMs;

    if (freq == UpdateFrequency.daily) {
      return diffMs >= const Duration(days: 1).inMilliseconds;
    } else if (freq == UpdateFrequency.weekly) {
      return diffMs >= const Duration(days: 7).inMilliseconds;
    }
    return true;
  }

  static Future<void> recordCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastCheck, DateTime.now().millisecondsSinceEpoch);
  }
}
