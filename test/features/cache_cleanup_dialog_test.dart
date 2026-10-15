import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/features/settings/utils/cache_cleanup_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheCleanupHelper Confirmation Dialog Interactions', () {
    testWidgets('Tapping Cancel returns false from dialog', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await CacheCleanupHelper.confirmAction(
                    context: context,
                    title: 'Очистити кеш?',
                    message: 'Ви впевнені, що хочете видалити файли?',
                  );
                },
                child: const Text('Confirm Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Confirm Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Очистити кеш?'), findsOneWidget);

      // Tap Cancel button
      final cancelBtn = find.byWidgetPredicate(
        (w) => w is TextButton && w.child is Text && (w.child as Text).data == 'Скасувати',
      );
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
      expect(find.text('Очистити кеш?'), findsNothing);
    });

    testWidgets('Tapping Delete returns true from dialog', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await CacheCleanupHelper.confirmAction(
                    context: context,
                    title: 'Очистити кеш?',
                    message: 'Ви впевнені, що хочете видалити файли?',
                  );
                },
                child: const Text('Confirm Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Confirm Dialog'));
      await tester.pumpAndSettle();

      // Tap Delete/Confirm button
      final deleteBtn = find.byWidgetPredicate(
        (w) => w is TextButton && w.child is Text && (w.child as Text).data == 'Видалити',
      );
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(find.text('Очистити кеш?'), findsNothing);
    });

    test('formatBytes formats bytes sizes accurately', () {
      expect(CacheCleanupHelper.formatBytes(0), equals('0 B'));
      expect(CacheCleanupHelper.formatBytes(512), equals('512 B'));
      expect(CacheCleanupHelper.formatBytes(2048), equals('2.0 KB'));
      expect(CacheCleanupHelper.formatBytes(10485760), equals('10.00 MB'));
    });
  });
}
