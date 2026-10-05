import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VisualizerSettingsProvider Unit Tests', () {
    test('Initializes with default software core settings', () {
      final provider = VisualizerSettingsProvider();
      expect(provider.core, equals(VisualizerCore.software));
      expect(provider.style, equals(VisualizerStyle.bars));
      expect(provider.attack, closeTo(0.60, 0.001));
      expect(provider.release, closeTo(0.40, 0.001));
      expect(provider.gravity, closeTo(-0.008, 0.001));
      expect(provider.bounce, closeTo(0.06, 0.001));
      expect(provider.amplitudeBoost, closeTo(1.0, 0.001));
    });

    test('Can change visualizer styles correctly', () {
      final provider = VisualizerSettingsProvider();
      
      provider.setStyle(VisualizerStyle.wave);
      expect(provider.style, equals(VisualizerStyle.wave));

      provider.setStyle(VisualizerStyle.circle);
      expect(provider.style, equals(VisualizerStyle.circle));

      provider.setStyle(VisualizerStyle.mirrored);
      expect(provider.style, equals(VisualizerStyle.mirrored));

      provider.setStyle(VisualizerStyle.bars);
      expect(provider.style, equals(VisualizerStyle.bars));
    });

    test('Can adjust physics sliders independently', () {
      final provider = VisualizerSettingsProvider();

      provider.setAttack(0.85);
      expect(provider.attack, closeTo(0.85, 0.001));

      provider.setRelease(0.25);
      expect(provider.release, closeTo(0.25, 0.001));

      provider.setGravity(-0.015);
      expect(provider.gravity, closeTo(-0.015, 0.001));

      provider.setBounce(0.09);
      expect(provider.bounce, closeTo(0.09, 0.001));

      provider.setAmplitudeBoost(1.50);
      expect(provider.amplitudeBoost, closeTo(1.50, 0.001));
    });

    test('Reset restores default values for active core', () {
      final provider = VisualizerSettingsProvider();

      provider.setAttack(0.99);
      provider.setRelease(0.01);
      provider.setAmplitudeBoost(2.0);

      expect(provider.attack, closeTo(0.99, 0.001));

      provider.reset();

      final defaults = CoreSettings.softwareDefaults();
      expect(provider.attack, closeTo(defaults.attack, 0.001));
      expect(provider.release, closeTo(defaults.release, 0.001));
      expect(provider.amplitudeBoost, closeTo(defaults.amplitudeBoost, 0.001));
    });
  });
}
