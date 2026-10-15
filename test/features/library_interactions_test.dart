import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/library/widgets/library_list_item.dart';
import 'package:music_flow_mobile/features/library/widgets/library_app_bar.dart';
import 'package:music_flow_mobile/features/library/screens/library_screen.dart' show SortOption;

class MockAudioProviderForLibrary extends ChangeNotifier implements AudioProvider {
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
  group('LibraryListItem Interactions', () {
    testWidgets('Tapping and long-pressing LibraryListItem triggers respective callbacks', (tester) async {
      bool tapped = false;
      bool longPressed = false;
      final song = SongModel(
        id: 'lib_song_1',
        title: 'Chervona Ruta',
        author: 'Volodymyr Ivasyuk',
        coverUrl: '',
        duration: const Duration(seconds: 210),
      );

      final audioMock = MockAudioProviderForLibrary();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AudioProvider>.value(
            value: audioMock,
            child: Scaffold(
              body: LibraryListItem(
                song: song,
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

      // Tap song tile
      await tester.tap(find.text('Chervona Ruta'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // Long press song tile
      await tester.longPress(find.text('Chervona Ruta'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });

    testWidgets('Selection mode displays checkmark and handles selection toggle', (tester) async {
      bool isSelected = false;
      final song = SongModel(
        id: 'lib_song_2',
        title: 'Stefania',
        author: 'Kalush Orchestra',
        coverUrl: '',
        duration: const Duration(seconds: 180),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AudioProvider>.value(
            value: MockAudioProviderForLibrary(),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: LibraryListItem(
                    song: song,
                    isSelected: isSelected,
                    isSelectionMode: true,
                    onTap: () => setState(() => isSelected = !isSelected),
                    onLongPress: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

      await tester.tap(find.text('Stefania'));
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('LibraryAppBar Interactions', () {
    testWidgets('Sort direction, sort menu, and refresh buttons trigger callbacks', (tester) async {
      bool refreshed = false;
      bool sortDirectionToggled = false;
      SortOption? selectedSort;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: LibraryAppBar(
              selectedCount: 0,
              isSelectionMode: false,
              isDescending: false,
              onClearSelection: () {},
              onDeleteSelected: () {},
              onToggleSortDirection: () => sortDirectionToggled = true,
              onSortSelected: (option) => selectedSort = option,
              onRefresh: () => refreshed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle sort direction
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      expect(sortDirectionToggled, isTrue);

      // Tap refresh
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(refreshed, isTrue);

      // Open sort popup menu
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Select 'За автором'
      final artistSortItem = find.text('За автором');
      expect(artistSortItem, findsOneWidget);
      await tester.tap(artistSortItem);
      await tester.pumpAndSettle();

      expect(selectedSort, equals(SortOption.author));
    });

    testWidgets('Selection mode shows close and delete buttons that fire callbacks', (tester) async {
      bool cleared = false;
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: LibraryAppBar(
              selectedCount: 3,
              isSelectionMode: true,
              isDescending: true,
              onClearSelection: () => cleared = true,
              onDeleteSelected: () => deleted = true,
              onToggleSortDirection: () {},
              onSortSelected: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('3'), findsOneWidget);

      // Tap clear selection
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(cleared, isTrue);

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });
}
