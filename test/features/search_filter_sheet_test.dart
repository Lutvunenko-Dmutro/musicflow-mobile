import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/search_filter_model.dart';
import 'package:music_flow_mobile/features/search/widgets/search_filter_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchFilterSheet Chip & Apply Interactions', () {
    testWidgets('Tapping format, duration chips and applying returns updated model', (tester) async {
      SearchFilterModel? appliedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SearchFilterSheet.show(
                    context,
                    filter: const SearchFilterModel(),
                    onApply: (res) => appliedFilter = res,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchFilterSheet), findsOneWidget);

      // Tap format chip: contains 'Кліп'
      final clipChip = find.textContaining('Кліп');
      expect(clipChip, findsOneWidget);
      await tester.ensureVisible(clipChip);
      await tester.tap(clipChip);
      await tester.pumpAndSettle();

      // Tap duration chip: contains 'До 5 хв'
      final under5Chip = find.textContaining('До 5 хв');
      expect(under5Chip, findsOneWidget);
      await tester.ensureVisible(under5Chip);
      await tester.tap(under5Chip);
      await tester.pumpAndSettle();

      // Tap apply button: contains 'Застосувати'
      final applyBtn = find.textContaining('Застосувати');
      expect(applyBtn, findsOneWidget);
      await tester.ensureVisible(applyBtn);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.format, equals('clip'));
      expect(appliedFilter!.durationFilter, equals(SearchDurationFilter.under5Min));
      expect(find.byType(SearchFilterSheet), findsNothing);
    });

    testWidgets('Tapping Reset restores default filter selections', (tester) async {
      SearchFilterModel? appliedFilter;
      const initial = SearchFilterModel(format: 'clip', genre: 'rock');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SearchFilterSheet.show(
                    context,
                    filter: initial,
                    onApply: (res) => appliedFilter = res,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap reset text button: 'Скинути'
      final resetBtn = find.text('Скинути');
      expect(resetBtn, findsOneWidget);
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Apply reset filter
      final applyBtn = find.textContaining('Застосувати');
      await tester.ensureVisible(applyBtn);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.format, equals('all'));
      expect(appliedFilter!.genre, equals('all'));
    });
  });
}
