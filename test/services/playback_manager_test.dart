import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/services/playback_manager.dart';

void main() {
  group('PlaybackManager.isYoutubeUrlExpired', () {
    test('returns true when URL has an expired timestamp', () {
      final pastUnix = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600; // 1 hour ago
      final url = 'https://rr2---sn-4g5edn6s.googlevideo.com/videoplayback?expire=$pastUnix&id=123';

      expect(PlaybackManager.isYoutubeUrlExpired(url), isTrue);
    });

    test('returns false when URL has a valid future timestamp (> 5 minutes ahead)', () {
      final futureUnix = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 14400; // 4 hours in future
      final url = 'https://rr2---sn-4g5edn6s.googlevideo.com/videoplayback?expire=$futureUnix&id=123';

      expect(PlaybackManager.isYoutubeUrlExpired(url), isFalse);
    });

    test('returns true when URL expires within 5 minute safety buffer', () {
      final soonUnix = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 120; // 2 minutes from now (< 5 min margin)
      final url = 'https://rr2---sn-4g5edn6s.googlevideo.com/videoplayback?expire=$soonUnix&id=123';

      expect(PlaybackManager.isYoutubeUrlExpired(url), isTrue);
    });

    test('returns false when URL does not contain expire query parameter', () {
      const url = 'https://example.com/audio.mp3';
      expect(PlaybackManager.isYoutubeUrlExpired(url), isFalse);
    });

    test('returns false for invalid or malformed URL without throwing', () {
      const malformed = 'not-a-valid-url';
      expect(PlaybackManager.isYoutubeUrlExpired(malformed), isFalse);
    });
  });
}
