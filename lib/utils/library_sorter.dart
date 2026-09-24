import 'dart:io';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/library/screens/library_screen.dart' show SortOption;
import 'package:music_flow_mobile/utils/app_logger.dart';

class LibrarySorter {
  static void sortSongs(List<SongModel> songs, SortOption currentSort, bool isDescending) {
    switch (currentSort) {
      case SortOption.title:
        songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.author:
        songs.sort((a, b) => a.author.compareTo(b.author));
        break;
      case SortOption.dateAdded:
        songs.sort((a, b) {
          int timeA = 0;
          int timeB = 0;
          if (a.localPath != null) {
            try {
              timeA = File(a.localPath!).lastModifiedSync().millisecondsSinceEpoch;
            } catch (e) {
              AppLogger.warning('Failed to get last modified for ${a.localPath}: $e', 'LIBRARY_SORTER');
            }
          }
          if (b.localPath != null) {
            try {
              timeB = File(b.localPath!).lastModifiedSync().millisecondsSinceEpoch;
            } catch (e) {
              AppLogger.warning('Failed to get last modified for ${b.localPath}: $e', 'LIBRARY_SORTER');
            }
          }
          return timeB.compareTo(timeA); // Descending by default (newest first)
        });
        break;
    }

    if (isDescending) {
      final reversed = songs.reversed.toList();
      songs.clear();
      songs.addAll(reversed);
    }
  }
}
