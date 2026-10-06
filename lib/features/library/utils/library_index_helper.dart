import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/models/sort_option.dart';

class LibraryIndexHelper {
  static List<String> getAvailableLetters(
    List<SongModel> songs,
    SortOption sort,
  ) {
    // Алфавітний індекс логічний лише при сортуванні за назвою або автором
    if (sort == SortOption.dateAdded || songs.length < 5) return const [];
    final letters = <String>{};

    for (final s in songs) {
      final text = (sort == SortOption.author ? s.author : s.title).trim();
      if (text.isEmpty) continue;
      final first = text[0].toUpperCase();
      if (RegExp(r'^[A-ZА-ЯІЇЄҐ]$').hasMatch(first)) {
        letters.add(first);
      } else {
        letters.add('#');
      }
    }

    final list = letters.toList()..sort((a, b) {
      if (a == '#') return -1;
      if (b == '#') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  static int findFirstIndexForLetter(
    List<SongModel> songs,
    SortOption sort,
    String letter,
  ) {
    return songs.indexWhere((s) {
      final text = (sort == SortOption.author ? s.author : s.title).trim();
      if (text.isEmpty) return false;
      final first = text[0].toUpperCase();
      if (letter == '#') {
        return !RegExp(r'^[A-ZА-ЯІЇЄҐ]$').hasMatch(first);
      }
      return first == letter;
    });
  }
}
