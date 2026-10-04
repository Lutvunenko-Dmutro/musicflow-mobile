import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_flow_mobile/utils/app_logger.dart';

class OnlineLyricsClient {
  static const String _lrclibUrl = 'https://lrclib.net/api/search';
  static const String _ovhUrl = 'https://api.lyrics.ovh/v1';

  static Future<String?> fetchFromOvh(String artist, String title) async {
    final cleanTitle = title
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .trim();
    final cleanArtist = artist.split(',').first.split('&').first.trim();
    final url = Uri.parse(
        '$_ovhUrl/${Uri.encodeComponent(cleanArtist)}/${Uri.encodeComponent(cleanTitle)}');

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

  static Future<String?> fetchFromLrclib(String artist, String title) async {
    final cleanTitle = title
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .trim();
    final cleanArtist = artist.split(',').first.split('&').first.trim();
    final url = Uri.parse(
        '$_lrclibUrl?track_name=${Uri.encodeComponent(cleanTitle)}&artist_name=${Uri.encodeComponent(cleanArtist)}');

    try {
      AppLogger.info('Fetching lyrics from $url', 'LYRICS');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          for (var item in data) {
            final syncedLyrics = item['syncedLyrics'] as String?;
            if (syncedLyrics != null && syncedLyrics.trim().isNotEmpty) {
              return syncedLyrics.trim();
            }
          }
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
