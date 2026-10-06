import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/equalizer/equalizer_presets_data.dart';
import 'package:music_flow_mobile/providers/equalizer/equalizer_settings_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('10-Band Equalizer Presets & Frequencies Tests', () {
    test('Frequencies array defines exactly 10 standard audio bands', () {
      expect(equalizerFrequencies.length, equals(10));
      expect(equalizerFrequencies.first, equals(31.0));
      expect(equalizerFrequencies.last, equals(16000.0));
    });

    test('All presets have exactly 10 frequency values', () {
      expect(equalizerPresetsData.isNotEmpty, isTrue);
      for (final entry in equalizerPresetsData.entries) {
        expect(
          entry.value.length,
          equals(10),
          reason: 'Preset "${entry.key}" should have exactly 10 band gains',
        );
      }
    });

    test('Common presets contain expected gain curves', () {
      expect(equalizerPresetsData['Звичайний'], equals(List.filled(10, 0.0)));
      expect(equalizerPresetsData['Рок'], isNotNull);
      expect(equalizerPresetsData['Bass Boost'], isNotNull);
      expect(equalizerPresetsData['Bass Boost']![0], greaterThan(5.0));
    });
  });

  group('EqualizerSettingsStorage Tests', () {
    test('Loads default settings with 10 bands', () async {
      final settings = await EqualizerSettingsStorage.loadSettings();
      expect(settings.isEnabled, isFalse);
      expect(settings.bassBoost, equals(0.0));
      expect(settings.virtualizer, equals(0.0));
      expect(settings.bandGains.length, equals(10));
      expect(settings.bandGains.every((g) => g == 0.0), isTrue);
    });

    test('Saves and restores individual band gain', () async {
      await EqualizerSettingsStorage.saveBandGain(0, 4.5);
      await EqualizerSettingsStorage.saveBandGain(9, -2.0);

      final settings = await EqualizerSettingsStorage.loadSettings();
      expect(settings.bandGains[0], equals(4.5));
      expect(settings.bandGains[9], equals(-2.0));
      expect(settings.bandGains[4], equals(0.0));
    });

    test('Saves and restores effects state', () async {
      await EqualizerSettingsStorage.saveEnabled(true);
      await EqualizerSettingsStorage.saveBass(0.75);
      await EqualizerSettingsStorage.saveVirtualizer(0.5);

      final settings = await EqualizerSettingsStorage.loadSettings();
      expect(settings.isEnabled, isTrue);
      expect(settings.bassBoost, equals(0.75));
      expect(settings.virtualizer, equals(0.5));
    });
  });
}
