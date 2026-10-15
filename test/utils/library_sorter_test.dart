import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/library/screens/library_screen.dart' show SortOption;
import 'package:music_flow_mobile/utils/library_sorter.dart';

void main() {
  group('LibrarySorter Unit Tests', () {
    final songA = SongModel(
      id: '1',
      title: 'Alpha Song',
      author: 'Zeta Artist',
      duration: const Duration(seconds: 100),
      coverUrl: '',
    );

    final songB = SongModel(
      id: '2',
      title: 'Beta Song',
      author: 'Beta Artist',
      duration: const Duration(seconds: 200),
      coverUrl: '',
    );

    final songC = SongModel(
      id: '3',
      title: 'Gamma Song',
      author: 'Alpha Artist',
      duration: const Duration(seconds: 300),
      coverUrl: '',
    );

    test('Sorts songs by title ascending and descending', () {
      final list = [songB, songC, songA];

      LibrarySorter.sortSongs(list, SortOption.title, false);
      expect(list.map((s) => s.title).toList(), equals(['Alpha Song', 'Beta Song', 'Gamma Song']));

      LibrarySorter.sortSongs(list, SortOption.title, true);
      expect(list.map((s) => s.title).toList(), equals(['Gamma Song', 'Beta Song', 'Alpha Song']));
    });

    test('Sorts songs by author ascending and descending', () {
      final list = [songA, songB, songC];

      LibrarySorter.sortSongs(list, SortOption.author, false);
      expect(list.map((s) => s.author).toList(), equals(['Alpha Artist', 'Beta Artist', 'Zeta Artist']));

      LibrarySorter.sortSongs(list, SortOption.author, true);
      expect(list.map((s) => s.author).toList(), equals(['Zeta Artist', 'Beta Artist', 'Alpha Artist']));
    });
  });
}
