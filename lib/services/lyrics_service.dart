import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audiotags/audiotags.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LyricsService {
  static const String _lrclibUrl = 'https://lrclib.net/api/search';
  static const String _ovhUrl = 'https://api.lyrics.ovh/v1';

  /// Завантажує текст пісні (спочатку шукає в локальному файлі, потім в інтернеті)
  Future<Map<String, String>?> getLyrics(SongModel song, {Function(Map<String, String>)? onUpdate}) async {
    // 1. Спробувати знайти локальний .lrc файл
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
        
        // Перевіряємо чи є дата останнього оновлення
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
        
        // Логіка користувача: якщо текст оновлювався нещодавно (наприклад, менше 7 днів тому), не чіпаємо ютуб/API.
        // Якщо ж пройшло більше часу — оновлюємо у фоні.
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
        
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
                
                // Видалимо _last_update_ms перед тим як відправити в UI
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
      // Cache the negative result so we don't spam the API on every playback
      await prefs.setString(cacheKey, "NOT_FOUND");
    }
    return freshLyrics;
  }

  Future<Map<String, String>?> _fetchFreshLyrics(SongModel song) async {
    Map<String, String>? finalResult;

    // 2. Якщо це YouTube трек (або завантажений з YouTube), спробувати стягнути субтитри з YouTube.
    // YouTube ID завжди має 11 символів.
    final ytService = locator<YoutubeService>();
    if (song.id.length == 11 && !song.id.contains('/')) {
      final captions = await ytService.getYoutubeCaptions(song.id);
      if (captions != null && captions.isNotEmpty) {
        AppLogger.info('Found YouTube captions for ${song.title}', 'LYRICS');
        finalResult = captions;
      }
    }

    // 3. Якщо локально і на ютубі тексту немає, шукаємо в lrclib
    if (finalResult == null) {
      final lrclibResult = await _fetchFromLrclib(song.author, song.title);
      if (lrclibResult != null) finalResult = {'Караоке (Lrclib)': lrclibResult};
    }

    // 4. Fallback: шукаємо звичайний текст в OVH
    if (finalResult == null) {
      final ovhResult = await _fetchFromOvh(song.author, song.title);
      if (ovhResult != null) finalResult = {'Текст (Lyrics.ovh)': ovhResult};
    }

    // 5. Ultimate Fallback для локальних пісень (каверів, рідкісних треків): 
    // Шукаємо цю пісню на YouTube і пробуємо витягнути авто-субтитри з першого знайденого відео!
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

  Future<String?> _fetchFromOvh(String artist, String title) async {
    final cleanTitle = title.replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
    final cleanArtist = artist.split(',').first.split('&').first.trim();

    final url = Uri.parse('$_ovhUrl/${Uri.encodeComponent(cleanArtist)}/${Uri.encodeComponent(cleanTitle)}');
    
    try {
      AppLogger.info('Fetching lyrics from OVH fallback $url', 'LYRICS');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lyrics = data['lyrics'] as String?;
        if (lyrics != null && lyrics.trim().isNotEmpty) {
          return lyrics.trim();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to fetch lyrics from OVH', e, null, 'LYRICS');
      if (e.toString().contains('SocketException')) rethrow;
    }
    return null;
  }

  Future<String?> _fetchFromLrclib(String artist, String title) async {
    final cleanTitle = title.replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
    final cleanArtist = artist.split(',').first.split('&').first.trim();

    final url = Uri.parse('$_lrclibUrl?track_name=${Uri.encodeComponent(cleanTitle)}&artist_name=${Uri.encodeComponent(cleanArtist)}');
    
    try {
      AppLogger.info('Fetching lyrics from $url', 'LYRICS');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Шукаємо перший результат із синхронізованим текстом (LRC)
          for (var item in data) {
            final syncedLyrics = item['syncedLyrics'] as String?;
            if (syncedLyrics != null && syncedLyrics.trim().isNotEmpty) {
              return syncedLyrics.trim();
            }
          }
          // Якщо синхронізованого немає, беремо звичайний
          final plainLyrics = data.first['plainLyrics'] as String?;
          if (plainLyrics != null && plainLyrics.trim().isNotEmpty) {
            return plainLyrics.trim();
          }
        }
      } else {
        AppLogger.warning('Lyrics not found: ${response.statusCode}', 'LYRICS');
      }
    } catch (e) {
      AppLogger.error('Failed to fetch lyrics from lrclib', e, null, 'LYRICS');
      if (e.toString().contains('SocketException')) rethrow;
    }
    
    return null;
  }
}
