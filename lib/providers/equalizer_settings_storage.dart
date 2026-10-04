import 'package:shared_preferences/shared_preferences.dart';

class EqualizerSavedSettings {
  final bool isEnabled;
  final double bassBoost;
  final double virtualizer;
  final List<double> bandGains;

  EqualizerSavedSettings({
    required this.isEnabled,
    required this.bassBoost,
    required this.virtualizer,
    required this.bandGains,
  });
}

class EqualizerSettingsStorage {
  static Future<EqualizerSavedSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('eq_enabled') ?? false;
    final bassBoost = prefs.getDouble('eq_bass') ?? 0.0;
    final virtualizer = prefs.getDouble('eq_virt') ?? 0.0;
    final gains = List<double>.filled(5, 0.0);
    for (int i = 0; i < 5; i++) {
      gains[i] = prefs.getDouble('eq_band_$i') ?? 0.0;
    }
    return EqualizerSavedSettings(
      isEnabled: isEnabled,
      bassBoost: bassBoost,
      virtualizer: virtualizer,
      bandGains: gains,
    );
  }

  static Future<void> saveEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eq_enabled', isEnabled);
  }

  static Future<void> saveBass(double bass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eq_bass', bass);
  }

  static Future<void> saveVirtualizer(double virt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eq_virt', virt);
  }

  static Future<void> saveBandGain(int bandIndex, double gain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eq_band_$bandIndex', gain);
  }
}
