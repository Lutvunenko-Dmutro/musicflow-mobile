import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/core/animations/animated_play_pause.dart';
import 'package:music_flow_mobile/core/animations/scale_tap_button.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/audio_visualizer.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MusicFlow UI Smoke Tests', () {
    testWidgets('AnimatedPlayPauseIcon renders and animates state cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedPlayPauseIcon(isPlaying: false, size: 48, color: Colors.white),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedPlayPauseIcon), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedPlayPauseIcon(isPlaying: true, size: 48, color: Colors.white),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AnimatedPlayPauseIcon), findsOneWidget);
    });

    testWidgets('ScaleTapButton triggers onTap without throwing', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScaleTapButton(
                onTap: () => tapped = true,
                child: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ScaleTapButton), findsOneWidget);
      await tester.tap(find.byType(ScaleTapButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('AudioVisualizer renders canvas smoothly with settings provider', (tester) async {
      final settings = VisualizerSettingsProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<VisualizerSettingsProvider>.value(
              value: settings,
              child: const SizedBox(
                width: 300,
                height: 50,
                child: AudioVisualizer(
                  isPlaying: false,
                  width: 300,
                  height: 50,
                  barCount: 30,
                  testMode: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AudioVisualizer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
