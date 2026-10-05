import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/lrclib_search_result.dart';

void main() {
  group('LrclibSearchResult', () {
    test('creates instance from json with synced lyrics', () {
      final json = {
        'id': 12345,
        'trackName': 'Bohemian Rhapsody',
        'artistName': 'Queen',
        'albumName': 'A Night at the Opera',
        'duration': 354.0,
        'syncedLyrics': '[00:10.00] Is this the real life?',
        'plainLyrics': 'Is this the real life?',
      };

      final result = LrclibSearchResult.fromJson(json);

      expect(result.id, 12345);
      expect(result.trackName, 'Bohemian Rhapsody');
      expect(result.artistName, 'Queen');
      expect(result.albumName, 'A Night at the Opera');
      expect(result.isKaraoke, isTrue);
      expect(result.bestLyrics, '[00:10.00] Is this the real life?');
    });

    test('handles plain lyrics correctly when syncedLyrics is null', () {
      final json = {
        'id': '67890',
        'trackName': 'Song Title',
        'artistName': 'Artist',
        'duration': 200,
        'syncedLyrics': null,
        'plainLyrics': 'Just plain text',
      };

      final result = LrclibSearchResult.fromJson(json);

      expect(result.id, 67890);
      expect(result.isKaraoke, isFalse);
      expect(result.bestLyrics, 'Just plain text');
    });
  });
}
