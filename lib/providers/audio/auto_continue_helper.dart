import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class AutoContinueHelper {
  static Future<List<SongModel>> fetchSimilarSongs({
    required SongModel currentSong,
    required Set<String> existingQueueIds,
  }) async {
    try {
      final ytService = locator<YoutubeService>();
      AppLogger.info('Triggering auto-continue for author: ${currentSong.author}', 'QUEUE');
      
      final results = await ytService.searchSongs(currentSong.author);
      return results.where((s) => !existingQueueIds.contains(s.id)).toList();
    } catch (e) {
      AppLogger.error('Failed auto-continue', e, null, 'QUEUE');
      return [];
    }
  }
}
