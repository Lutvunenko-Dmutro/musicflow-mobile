import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/language_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/system_settings_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'show_media_notification': true,
      'download_path': '/storage/music',
    });
  });

  group('SystemSettingsCard Interactions', () {
    testWidgets('Toggling media notification switch updates preference and UI', (tester) async {
      final langProvider = LanguageProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageProvider>.value(
              value: langProvider,
              child: const SystemSettingsCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      final initialSwitch = tester.widget<Switch>(switchFinder);
      expect(initialSwitch.value, isTrue);

      // Tap the switch to turn it off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<Switch>(switchFinder);
      expect(updatedSwitch.value, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_media_notification'), isFalse);
    });
  });
}
