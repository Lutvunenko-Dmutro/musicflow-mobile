import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/l10n/app_language.dart';
import 'package:music_flow_mobile/providers/language_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/language_selector_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageSelectorSheet Interactions', () {
    testWidgets('Tapping English language tile updates LanguageProvider and dismisses sheet', (tester) async {
      final languageProvider = LanguageProvider();

      expect(languageProvider.currentLanguage, equals(AppLanguage.uk));

      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => LanguageSelectorSheet.show(context),
                    child: const Text('Open Language Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Open Language Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Українська'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Tap English tile
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Verify language changed
      expect(languageProvider.currentLanguage, equals(AppLanguage.en));
    });
  });
}
