import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_presets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Equalizer Presets Tap Interactions', () {
    testWidgets('Tapping different equalizer preset pills updates selected preset', (tester) async {
      String currentPreset = 'Звичайний';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return EqualizerPresetsWidget(
                  activePreset: currentPreset,
                  onPresetSelected: (newPreset) {
                    setState(() => currentPreset = newPreset);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find preset by text, e.g. 'Рок'
      final rockPresetFinder = find.text('Рок');
      expect(rockPresetFinder, findsOneWidget);

      await tester.tap(rockPresetFinder);
      await tester.pumpAndSettle();
      expect(currentPreset, equals('Рок'));

      // Find 'Bass Boost' preset
      final bassBoostFinder = find.text('Bass Boost');
      expect(bassBoostFinder, findsOneWidget);

      await tester.tap(bassBoostFinder);
      await tester.pumpAndSettle();
      expect(currentPreset, equals('Bass Boost'));

      // Find 'Джаз' preset
      final jazzFinder = find.text('Джаз');
      expect(jazzFinder, findsOneWidget);

      await tester.tap(jazzFinder);
      await tester.pumpAndSettle();
      expect(currentPreset, equals('Джаз'));
    });
  });
}
