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
        final hasKaraoke = mapString.values.any((text) => RegExp(r'\[\d+:\d+').hasMatch(text));
        if (!hasKaraoke || lastUpdateMs == null || (nowMs - lastUpdateMs) > sevenDaysMs) {
          AppLogger.info('Lyrics cache has no karaoke or is old, updating for ${song.title}', 'LYRICS');
          Future.microtask(() async {
            final freshLyrics = await _fetchFreshLyrics(song);
            if (freshLyrics != null && freshLyrics.isNotEmpty) {
              freshLyrics['_last_update_ms'] = DateTime.now().millisecondsSinceEpoch.toString();
              mapString.forEach((k, v) {
                if (!freshLyrics.containsKey(k)) freshLyrics[k] = v;
              });
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

  Future<String?> getPreferredLyricsKey(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_lyrics_$songId');
  }

  Future<void> savePreferredLyricsKey(String songId, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_lyrics_$songId', key);
  }

  Future<void> saveCustomLyrics(SongModel song, String label, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'lyrics_cache_${song.id}';
    final cachedData = prefs.getString(cacheKey);
    final map = <String, String>{};
    if (cachedData != null && cachedData != "NOT_FOUND") {
      try {
        final decoded = json.decode(cachedData) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (k != '_last_update_ms') map[k] = v.toString();
        });
      } catch (_) {}
    }
    if (label.contains('LRCLIB')) {
      map.remove('Караоке (LRCLIB)');
    }
    map[label] = text;
    map['_last_update_ms'] = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString(cacheKey, json.encode(map));
    await savePreferredLyricsKey(song.id, label);
  }

  Future<void> removeCustomLyrics(String songId, String label) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'lyrics_cache_$songId';
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null && cachedData != "NOT_FOUND") {
      try {
        final map = json.decode(cachedData) as Map<String, dynamic>;
        map.remove(label);
        await prefs.setString(cacheKey, json.encode(map));
      } catch (_) {}
    }
    final preferred = await getPreferredLyricsKey(songId);
    if (preferred == label) await prefs.remove('preferred_lyrics_$songId');
  }

  Future<void> resetAllLyrics(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lyrics_cache_$songId');
    await prefs.remove('preferred_lyrics_$songId');
  }

  Future<Map<String, String>?> _fetchFreshLyrics(SongModel song) async {
    final results = <String, String>{};

    // 1. First priority: LRCLIB (dedicated high quality synchronized LRC karaoke)
    try {
      final lrclibResult = await OnlineLyricsClient.fetchFromLrclib(song.author, song.title);
      if (lrclibResult != null && lrclibResult.isNotEmpty) {
        results['Караоке (LRCLIB)'] = lrclibResult;
      }
    } catch (_) {}

    // 2. YouTube captions (if online video)
    final ytService = locator<YoutubeService>();
    if (song.id.length == 11 && !song.id.contains('/')) {
      try {
        final captions = await ytService.getYoutubeCaptions(song.id);
        if (captions != null && captions.isNotEmpty) {
          for (final entry in captions.entries) {
            final key = entry.key.contains('Auto') ? 'YouTube (авто)' : 'YouTube (${entry.key})';
            results[key] = entry.value;
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: lyrics.ovh plain lyrics if nothing found
    if (results.isEmpty) {
      try {
        final ovhResult = await OnlineLyricsClient.fetchFromOvh(song.author, song.title);
        if (ovhResult != null) results['Текст (Lyrics.ovh)'] = ovhResult;
      } catch (_) {}
    }

    // 4. Local song ultimate fallback to YouTube search
    if (results.isEmpty && song.isLocal) {
      try {
        final searchResults = await ytService.searchSongs('${song.author} ${song.title}');
        if (searchResults.isNotEmpty) {
          final firstVideo = searchResults.first;
          final captions = await ytService.getYoutubeCaptions(firstVideo.id);
          if (captions != null && captions.isNotEmpty) {
            results.addAll(captions);
          }
        }
      } catch (e) {
        if (e.toString().contains('SocketException')) rethrow;
      }
    }

    return results.isNotEmpty ? results : null;
  }
}
