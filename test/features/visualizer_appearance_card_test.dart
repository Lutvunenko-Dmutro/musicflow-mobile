import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_appearance_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_segment_button.dart';

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

  Widget buildTestCard(VisualizerSettingsProvider settings) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: settings,
            builder: (context, _) => VisualizerAppearanceCard(settings: settings),
          ),
        ),
      ),
    );
  }

  group('VisualizerAppearanceCard Widget Tests', () {
    testWidgets('Toggles placement between bottom and cover aura', (tester) async {
      final settings = VisualizerSettingsProvider();

      await tester.pumpWidget(buildTestCard(settings));
      expect(settings.position, equals(VisualizerPosition.bottom));

      final coverAuraBtn = find.byWidgetPredicate(
        (w) => w is VisualizerSegmentButton<VisualizerPosition> &&
               w.value == VisualizerPosition.coverAura,
      );
      expect(coverAuraBtn, findsOneWidget);

      await tester.tap(coverAuraBtn);
      await tester.pumpAndSettle();

      expect(settings.position, equals(VisualizerPosition.coverAura));
    });

    testWidgets('Displays all 4 aura mirror modes and updates provider on tap', (tester) async {
      final settings = VisualizerSettingsProvider();

      await tester.pumpWidget(buildTestCard(settings));
      settings.setPosition(VisualizerPosition.coverAura);
      await tester.pumpAndSettle();

      final mirror4Btn = find.byWidgetPredicate(
        (w) => w is VisualizerSegmentButton<AuraSpectrumMode> &&
               w.value == AuraSpectrumMode.mirrored4Side,
      );
      final mirror2HBtn = find.byWidgetPredicate(
        (w) => w is VisualizerSegmentButton<AuraSpectrumMode> &&
               w.value == AuraSpectrumMode.mirrored2H,
      );
      final mirror2VBtn = find.byWidgetPredicate(
        (w) => w is VisualizerSegmentButton<AuraSpectrumMode> &&
               w.value == AuraSpectrumMode.mirrored2V,
      );
      final liveBtn = find.byWidgetPredicate(
        (w) => w is VisualizerSegmentButton<AuraSpectrumMode> &&
               w.value == AuraSpectrumMode.live,
      );

      expect(mirror4Btn, findsOneWidget);
      expect(mirror2HBtn, findsOneWidget);
      expect(mirror2VBtn, findsOneWidget);
      expect(liveBtn, findsOneWidget);

      await tester.tap(mirror4Btn);
      await tester.pumpAndSettle();
      expect(settings.auraSpectrumMode, equals(AuraSpectrumMode.mirrored4Side));

      await tester.tap(mirror2HBtn);
      await tester.pumpAndSettle();
      expect(settings.auraSpectrumMode, equals(AuraSpectrumMode.mirrored2H));

      await tester.tap(mirror2VBtn);
      await tester.pumpAndSettle();
      expect(settings.auraSpectrumMode, equals(AuraSpectrumMode.mirrored2V));

      await tester.tap(liveBtn);
      await tester.pumpAndSettle();
      expect(settings.auraSpectrumMode, equals(AuraSpectrumMode.live));
    });

    testWidgets('Toggles cover shape and color theme', (tester) async {
      final settings = VisualizerSettingsProvider();

      await tester.pumpWidget(buildTestCard(settings));
      await tester.pumpAndSettle();

      final vinylBtn = find.byWidgetPredicate(
        (w) => w is VisualizerSegmentButton<VisualizerCoverShape> &&
               w.value == VisualizerCoverShape.circleVinyl,
      );
      await tester.tap(vinylBtn);
      await tester.pumpAndSettle();
      expect(settings.coverShape, equals(VisualizerCoverShape.circleVinyl));

      final adaptiveBtn = find.byWidgetPredicate(
        (w) => w is VisualizerSegmentButton<VisualizerColorScheme> &&
               w.value == VisualizerColorScheme.adaptive,
      );
      await tester.tap(adaptiveBtn);
      await tester.pumpAndSettle();
      expect(settings.colorScheme, equals(VisualizerColorScheme.adaptive));
    });
  });
}
