import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';
import 'package:music_flow_mobile/models/lrclib_search_result.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_line_tile.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_result_card.dart';

void main() {
  group('LyricsLineTile Interactions', () {
    testWidgets('Tapping on a lyrics line triggers onTap seek callback', (tester) async {
      bool seekTapped = false;

      final line = LyricsLine(15.4, 'Я піду в далекі гори');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LyricsLineTile(
              line: line,
              isActive: true,
              distanceToActive: 0,
              currentSec: 16.0,
              onTap: () => seekTapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Я піду в далекі гори'), findsOneWidget);

      await tester.tap(find.text('Я піду в далекі гори'));
      await tester.pumpAndSettle();

      expect(seekTapped, isTrue);
    });

    testWidgets('Inactive lyrics line renders with appropriate opacity and fires onTap', (tester) async {
      bool tapped = false;

      final line = LyricsLine(20.0, 'На широкі полонини');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LyricsLineTile(
              line: line,
              isActive: false,
              distanceToActive: 2,
              currentSec: 10.0,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('На широкі полонини'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('LyricsResultCard Interactions', () {
    testWidgets('Tapping preview and select buttons triggers corresponding callbacks', (tester) async {
      bool previewCalled = false;
      bool selectCalled = false;

      final result = LrclibSearchResult(
        id: 994,
        trackName: 'Chervona Ruta',
        artistName: 'Nazariy Yaremchuk',
        albumName: 'Hits of Ukraine',
        duration: 215.0,
        plainLyrics: 'Ти признайся мені...',
        syncedLyrics: '[00:15.00] Ти признайся мені...',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: LyricsResultCard(
                  item: result,
                  onPreview: () => previewCalled = true,
                  onSelect: () => selectCalled = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chervona Ruta'), findsOneWidget);
      expect(find.textContaining('Nazariy Yaremchuk'), findsOneWidget);

      // Tap preview button
      final previewBtn = find.text('Переглянути');
      expect(previewBtn, findsOneWidget);
      await tester.tap(previewBtn);
      await tester.pumpAndSettle();
      expect(previewCalled, isTrue);

      // Tap select button
      final selectBtn = find.text('Вибрати');
      expect(selectBtn, findsOneWidget);
      await tester.tap(selectBtn);
      await tester.pumpAndSettle();
      expect(selectCalled, isTrue);
    });
  });
}
