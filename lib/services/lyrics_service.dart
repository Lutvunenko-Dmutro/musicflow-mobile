import 'dart:convert';
import 'package:audiotags/audiotags.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/services/online_lyrics_client.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LyricsService {
  Future<Map<String, String>?> getLyrics(
    SongModel song, {
    Function(Map<String, String>)? onUpdate,
  }) async {
    if (song.isLocal && song.localPath != null) {
      try {
        final tag = await AudioTags.read(song.localPath!);
        if (tag != null && tag.lyrics != null && tag.lyrics!.trim().isNotEmpty) {
          AppLogger.info('Found local lyrics for ${song.title}', 'LYRICS');
          return {'Вбудований текст': tag.lyrics!};
        }
      } catch (e) {
        AppLogger.error('Failed to read local lyrics', e, null, 'LYRICS');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'lyrics_cache_${song.id}';
    final cachedData = prefs.getString(cacheKey);
    
    if (cachedData != null) {
      if (cachedData == "NOT_FOUND") {
        AppLogger.info('Lyrics previously not found for ${song.title}, skipping API calls', 'LYRICS');
        return null;
      }
      try {
        final decoded = json.decode(cachedData) as Map<String, dynamic>;
        int? lastUpdateMs;
        if (decoded['_last_update_ms'] != null) {
          lastUpdateMs = int.tryParse(decoded['_last_update_ms'].toString());
        }
        final mapString = <String, String>{};
        decoded.forEach((key, value) {
          if (key != '_last_update_ms') {
            mapString[key] = value.toString();
          }
        });
        
        AppLogger.info('Found cached lyrics for ${song.title}', 'LYRICS');
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
        
        if (lastUpdateMs == null || (nowMs - lastUpdateMs) > sevenDaysMs) {
          AppLogger.info('Lyrics cache is old, scheduling background update for ${song.title}', 'LYRICS');
          Future.microtask(() async {
            final freshLyrics = await _fetchFreshLyrics(song);
            if (freshLyrics != null && freshLyrics.isNotEmpty) {
              freshLyrics['_last_update_ms'] = DateTime.now().millisecondsSinceEpoch.toString();
              final freshData = json.encode(freshLyrics);
              if (freshData != cachedData) {
                await prefs.setString(cacheKey, freshData);
                AppLogger.info('Updated lyrics cache in background for ${song.title}', 'LYRICS');
                freshLyrics.remove('_last_update_ms');
                onUpdate?.call(freshLyrics);
              }
            }
          });
        }
        return mapString;
      } catch (e) {
        AppLogger.warning('Failed to parse cached lyrics', 'LYRICS');
      }
    }

    final freshLyrics = await _fetchFreshLyrics(song);
    if (freshLyrics != null && freshLyrics.isNotEmpty) {
      freshLyrics['_last_update_ms'] = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(cacheKey, json.encode(freshLyrics));
      freshLyrics.remove('_last_update_ms');
    } else {
      await prefs.setString(cacheKey, "NOT_FOUND");
    }
    return freshLyrics;
  }

  Future<Map<String, String>?> _fetchFreshLyrics(SongModel song) async {
    Map<String, String>? finalResult;

    final ytService = locator<YoutubeService>();
    if (song.id.length == 11 && !song.id.contains('/')) {
      final captions = await ytService.getYoutubeCaptions(song.id);
      if (captions != null && captions.isNotEmpty) {
        AppLogger.info('Found YouTube captions for ${song.title}', 'LYRICS');
        finalResult = captions;
      }
    }

    if (finalResult == null) {
      final lrclibResult = await OnlineLyricsClient.fetchFromLrclib(song.author, song.title);
      if (lrclibResult != null) finalResult = {'Караоке (Lrclib)': lrclibResult};
    }

    if (finalResult == null) {
      final ovhResult = await OnlineLyricsClient.fetchFromOvh(song.author, song.title);
      if (ovhResult != null) finalResult = {'Текст (Lyrics.ovh)': ovhResult};
    }

    if (finalResult == null && song.isLocal) {
      try {
        AppLogger.info('Trying ultimate fallback: searching YouTube for ${song.title}...', 'LYRICS');
        final searchResults = await ytService.searchSongs('${song.author} ${song.title}');
        if (searchResults.isNotEmpty) {
          final firstVideo = searchResults.first;
          final captions = await ytService.getYoutubeCaptions(firstVideo.id);
          if (captions != null && captions.isNotEmpty) {
            AppLogger.info('Found ultimate fallback captions from YouTube video: ${firstVideo.title}', 'LYRICS');
            finalResult = captions;
          }
        }
      } catch (e) {
        AppLogger.error('Ultimate fallback failed', e, null, 'LYRICS');
        if (e.toString().contains('SocketException')) rethrow;
      }
    }

    return finalResult;
  }
}
