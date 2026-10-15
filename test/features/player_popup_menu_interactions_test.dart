import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/features/player/widgets/player_popup_menu.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class MockAudioProviderForPopup extends ChangeNotifier implements AudioProvider {
  bool visualizerToggled = false;
  bool lyricsToggled = false;
  bool _showVisualizer = false;
  bool _showInlineLyrics = false;

  @override
  bool get showVisualizer => _showVisualizer;

  @override
  bool get showInlineLyrics => _showInlineLyrics;

  @override
  Future<void> toggleVisualizer() async {
    _showVisualizer = !_showVisualizer;
    visualizerToggled = true;
    notifyListeners();
  }

  @override
  Future<void> toggleInlineLyrics() async {
    _showInlineLyrics = !_showInlineLyrics;
    lyricsToggled = true;
    notifyListeners();
  }

  @override
  SongModel? get currentSong => SongModel(
        id: 'popup_s1',
        title: 'Popup Song',
        author: 'Artist',
        coverUrl: '',
        duration: const Duration(seconds: 200),
      );

  @override
  Map<String, String>? get availableLyrics => null;

  @override
  bool get isLyricsDisabledForCurrentSong => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PlayerPopupMenu Interactions', () {
    testWidgets('Tapping menu icon opens popup and tapping toggle visualizer fires callback', (tester) async {
      final mock = MockAudioProviderForPopup();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                PlayerPopupMenu(audioProvider: mock),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 3-dots icon
      final moreIcon = find.byIcon(Icons.more_vert);
      expect(moreIcon, findsOneWidget);
      await tester.tap(moreIcon);
      await tester.pumpAndSettle();

      // Verify menu items appear
      expect(find.text('Показати візуалізатор'), findsOneWidget);
      expect(find.textContaining('караоке'), findsWidgets);

      // Tap toggle visualizer
      await tester.tap(find.text('Показати візуалізатор'));
      await tester.pumpAndSettle();

      expect(mock.visualizerToggled, isTrue);
      expect(mock.showVisualizer, isTrue);
    });

    testWidgets('Tapping toggle inline lyrics in popup fires callback', (tester) async {
      final mock = MockAudioProviderForPopup();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                PlayerPopupMenu(audioProvider: mock),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 3-dots icon
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap mini karaoke toggle
      final karaokeItem = find.textContaining('міні-караоке');
      expect(karaokeItem, findsOneWidget);
      await tester.tap(karaokeItem);
      await tester.pumpAndSettle();

      expect(mock.lyricsToggled, isTrue);
      expect(mock.showInlineLyrics, isTrue);
    });
  });
}
