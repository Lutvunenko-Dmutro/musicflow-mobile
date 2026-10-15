import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_presets_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.example.music_flow_mobile/visualizer_method'),
          (MethodCall methodCall) async => null,
        );
  });

  group('VisualizerPresetsRow Tap Interactions', () {
    testWidgets('Tapping presets applies settings and updates active preset callback', (tester) async {
      final settings = VisualizerSettingsProvider();
      String selectedPreset = 'classic';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 120,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return VisualizerPresetsRow(
                      settings: settings,
                      activePreset: selectedPreset,
                      onSelectPreset: (key) {
                        setState(() => selectedPreset = key);
                        VisualizerPresetsRow.applyPreset(key, settings);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Динамічний Бас'
      final bassPreset = find.text('Динамічний Бас');
      expect(bassPreset, findsOneWidget);
      await tester.tap(bassPreset);
      await tester.pumpAndSettle();

      expect(selectedPreset, equals('dynamic_bass'));
      expect(settings.style, equals(VisualizerStyle.bars));
      expect(settings.amplitudeBoost, closeTo(1.35, 0.001));

      // Tap 'Плавна Хвиля'
      final wavePreset = find.text('Плавна Хвиля');
      expect(wavePreset, findsOneWidget);
      await tester.tap(wavePreset);
      await tester.pumpAndSettle();

      expect(selectedPreset, equals('smooth_wave'));
      expect(settings.style, equals(VisualizerStyle.wave));

      // Scroll if needed and tap 'Неонове Коло'
      await tester.drag(find.byType(ListView), const Offset(-150, 0));
      await tester.pumpAndSettle();

      final circlePreset = find.text('Неонове Коло');
      expect(circlePreset, findsOneWidget);
      await tester.tap(circlePreset);
      await tester.pumpAndSettle();

      expect(selectedPreset, equals('neon_circle'));
      expect(settings.style, equals(VisualizerStyle.circle));
    });
  });
}
