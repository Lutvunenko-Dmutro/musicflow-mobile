import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/search_filter_model.dart';
import 'package:music_flow_mobile/features/search/widgets/search_input_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchInputCard Interactions & Typing Tests', () {
    testWidgets('Entering text, clearing, and submitting search query', (tester) async {
      final controller = TextEditingController();
      bool searchTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return SearchInputCard(
                  controller: controller,
                  filter: SearchFilterModel(),
                  isSearching: false,
                  onSearch: () => searchTriggered = true,
                  onOpenFilter: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // 1. Enter search text
      await tester.enterText(textField, 'The Beatles');
      await tester.pumpAndSettle();
      expect(controller.text, equals('The Beatles'));

      // 2. Clear text via clear icon button
      final clearBtn = find.byIcon(Icons.clear);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);

      // 3. Enter new query and submit via search button
      await tester.enterText(textField, 'Queen');
      await tester.pumpAndSettle();

      final searchBtn = find.byWidgetPredicate((w) => w is ElevatedButton);
      expect(searchBtn, findsOneWidget);
      await tester.tap(searchBtn);
      await tester.pumpAndSettle();

      expect(searchTriggered, isTrue);
      expect(controller.text, equals('Queen'));
    });
  });
}
