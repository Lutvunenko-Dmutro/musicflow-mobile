import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_flow_mobile/models/lrclib_search_result.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class OnlineLyricsClient {
  static const String _lrclibUrl = 'https://lrclib.net/api/search';
  static const String _ovhUrl = 'https://api.lyrics.ovh/v1';
  static const Map<String, String> _headers = {
    'User-Agent': 'MusicFlow/1.0 (https://github.com/music-flow)',
  };

  static ({String artist, String track}) cleanArtistAndTitle(String rawArtist, String rawTitle) {
    var title = rawTitle
        .replaceAll(RegExp(r'[\(\[].*?[\)\]]'), '')
        .replaceAll(RegExp(r'(official\s*(music\s*)?video|lyric\s*video|audio|remastered|hd|4k)', caseSensitive: false), '')
        .trim();

    var artist = rawArtist
        .replaceAll(RegExp(r'(official|vevo|\s*-\s*topic|topic|music|channel|records)', caseSensitive: false), '')
        .split(',').first.split('&').first.trim();
    if (artist.isEmpty) artist = rawArtist.trim();

    if (title.contains(' - ')) {
      final parts = title.split(' - ');
      final candArtist = parts[0].trim();
      final candTrack = parts.sublist(1).join(' - ').trim();
      if (candArtist.isNotEmpty && candTrack.isNotEmpty) {
        return (artist: candArtist, track: candTrack);
      }
    }

    return (artist: artist, track: title);
  }

  static Future<String?> fetchFromOvh(String artist, String title) async {
    final info = cleanArtistAndTitle(artist, title);
    final url = Uri.parse('$_ovhUrl/${Uri.encodeComponent(info.artist)}/${Uri.encodeComponent(info.track)}');

    try {
      AppLogger.info('Fetching lyrics from OVH fallback $url', 'LYRICS');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lyrics = data['lyrics'] as String?;
        if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();
      }
    } catch (e) {
      AppLogger.error('Failed to fetch lyrics from OVH', e, null, 'LYRICS');
      if (e.toString().contains('SocketException')) rethrow;
    }
    return null;
  }

  static Future<String?> fetchFromLrclib(String rawArtist, String rawTitle) async {
    final info = cleanArtistAndTitle(rawArtist, rawTitle);

    // 1. Try track_name & artist_name
    try {
      final url = Uri.parse('$_lrclibUrl?track_name=${Uri.encodeComponent(info.track)}&artist_name=${Uri.encodeComponent(info.artist)}');
      AppLogger.info('Fetching lyrics from $url', 'LYRICS');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          final synced = item['syncedLyrics'] as String?;
          if (synced != null && synced.trim().isNotEmpty) return synced.trim();
        }
      }
    } catch (_) {}

    // 2. Fallback to general query search
    try {
      final searchResults = await searchLrclib('${info.artist} ${info.track}');
      for (var item in searchResults) {
        if (item.isKaraoke) return item.syncedLyrics!.trim();
      }
      if (searchResults.isNotEmpty && searchResults.first.bestLyrics.isNotEmpty) {
        return searchResults.first.bestLyrics;
      }
    } catch (_) {}

    return null;
  }

  static Future<List<LrclibSearchResult>> searchLrclib(String query) async {
    final cleanQuery = query
        .replaceAll(RegExp(r'[\(\[].*?[\)\]]'), '')
        .replaceAll(RegExp(r'(official\s*(music\s*)?video|lyric\s*video|audio|remastered)', caseSensitive: false), '')
        .trim();
    final effectiveQuery = cleanQuery.isNotEmpty ? cleanQuery : query;
    final url = Uri.parse('$_lrclibUrl?q=${Uri.encodeComponent(effectiveQuery)}');

    try {
      AppLogger.info('Searching LRCLIB for: $effectiveQuery', 'LYRICS');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((item) => LrclibSearchResult.fromJson(item as Map<String, dynamic>)).toList();
        list.sort((a, b) => (b.isKaraoke ? 1 : 0).compareTo(a.isKaraoke ? 1 : 0));
        return list;
      }
    } catch (e) {
      AppLogger.error('Failed to search LRCLIB', e, null, 'LYRICS');
      if (e.toString().contains('SocketException')) rethrow;
    }
    return [];
  }
}
