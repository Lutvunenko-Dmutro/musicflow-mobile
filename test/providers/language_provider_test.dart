import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/l10n/app_language.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/providers/language_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/language_selector_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLanguage Tests', () {
    test('resolves correct language by code', () {
      expect(AppLanguage.fromCode('uk'), AppLanguage.uk);
      expect(AppLanguage.fromCode('UK'), AppLanguage.uk);
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('EN'), AppLanguage.en);
      expect(AppLanguage.fromCode(null), AppLanguage.uk);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.uk);
    });

    test('metadata properties are populated', () {
      expect(AppLanguage.uk.code, 'uk');
      expect(AppLanguage.uk.title, 'Українська');
      expect(AppLanguage.uk.flag, isNotEmpty);

      expect(AppLanguage.en.code, 'en');
      expect(AppLanguage.en.title, 'English');
      expect(AppLanguage.en.flag, isNotEmpty);
    });
  });

  group('AppStrings Contract Tests', () {
    test('Ukrainian strings match expected translations', () {
      final uk = AppStrings.get(AppLanguage.uk);
      expect(uk.search, 'Пошук');
      expect(uk.library, 'Медіатека');
      expect(uk.history, 'Історія');
      expect(uk.settings, 'Налаштування');
      expect(uk.nowPlaying, 'Зараз грає');
      expect(uk.playback, 'Відтворення');
    });

    test('English strings match expected translations', () {
      final en = AppStrings.get(AppLanguage.en);
      expect(en.search, 'Search');
      expect(en.library, 'Library');
      expect(en.history, 'History');
      expect(en.settings, 'Settings');
      expect(en.nowPlaying, 'Now Playing');
      expect(en.playback, 'Playback');
    });
  });

  group('LanguageProvider State & Persistence Tests', () {
    test('defaults to Ukrainian and persists language switch', () async {
      final provider = LanguageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.currentLanguage, AppLanguage.uk);
      expect(provider.strings.search, 'Пошук');
      expect(provider.locale.languageCode, 'uk');

      await provider.setLanguage(AppLanguage.en);

      expect(provider.currentLanguage, AppLanguage.en);
      expect(provider.strings.search, 'Search');
      expect(provider.locale.languageCode, 'en');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'en');

      // Verify restored on new instance
      final restored = LanguageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(restored.currentLanguage, AppLanguage.en);
      expect(restored.strings.search, 'Search');
    });
  });

  group('LanguageSelectorSheet Widget Tests', () {
    testWidgets('renders language selector and switches active language', (tester) async {
      final provider = LanguageProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => LanguageSelectorSheet.show(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Вибір мови'), findsOneWidget);
      expect(find.text('Українська'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Tap English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Bottom sheet closed and language changed
      expect(provider.currentLanguage, AppLanguage.en);
    });
  });
}
