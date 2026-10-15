import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/history_model.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/library/widgets/history_list_item.dart';

class MockAudioProviderForHistory extends ChangeNotifier implements AudioProvider {
  final SongModel? _song = null;
  final bool _isPlaying = false;

  @override
  SongModel? get currentSong => _song;

  @override
  bool get isPlaying => _isPlaying;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HistoryListItem Interactions', () {
    testWidgets('Tapping HistoryListItem triggers onTap callback', (tester) async {
      bool tapped = false;
      bool longPressed = false;

      final historyItem = HistoryModel(
        id: '/storage/emulated/0/Music/track1.mp3',
        title: 'History Track',
        author: 'Artist History',
        coverUrl: '',
        durationMs: 240000,
        lastPlayedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        playCount: 12,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AudioProvider>.value(
            value: MockAudioProviderForHistory(),
            child: Scaffold(
              body: HistoryListItem(
                item: historyItem,
                isSelected: false,
                isSelectionMode: false,
                onTap: () => tapped = true,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('History Track'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // Tap history item
      await tester.tap(find.text('History Track'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // Long press history item
      await tester.longPress(find.text('History Track'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });

    testWidgets('HistoryListItem reflects selection state in selection mode', (tester) async {
      bool isSelected = false;

      final historyItem = HistoryModel(
        id: '/storage/emulated/0/Music/track2.mp3',
        title: 'Selected History Track',
        author: 'Artist',
        coverUrl: '',
        durationMs: 180000,
        lastPlayedAt: DateTime.now().subtract(const Duration(hours: 1)),
        playCount: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AudioProvider>.value(
            value: MockAudioProviderForHistory(),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: HistoryListItem(
                    item: historyItem,
                    isSelected: isSelected,
                    isSelectionMode: true,
                    onTap: () => setState(() => isSelected = !isSelected),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

      await tester.tap(find.text('Selected History Track'));
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
