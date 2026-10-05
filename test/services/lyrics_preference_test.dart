import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/audio/lyrics_manager_mixin.dart';
import 'package:music_flow_mobile/services/lyrics_service.dart';
import 'package:music_flow_mobile/services/online_lyrics_client.dart';

class TestLyricsManager with ChangeNotifier, LyricsManagerMixin {
  void setCustomLyricsForTest(Map<String, String> lyrics) {
    for (final entry in lyrics.entries) {
      changeLyricsTrack(entry.key);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lyrics Preferences & Disabled State', () {
    test('LyricsService saves and retrieves preferred lyrics key', () async {
      final service = LyricsService();
      await service.savePreferredLyricsKey('song_1', LyricsManagerMixin.disabledLyricsKey);
      final preferred = await service.getPreferredLyricsKey('song_1');
      expect(preferred, equals(LyricsManagerMixin.disabledLyricsKey));
    });

    test('LyricsManagerMixin marks current lyrics as null when disabled', () {
      final manager = TestLyricsManager();
      manager.changeLyricsTrack(LyricsManagerMixin.disabledLyricsKey, songId: 'test_song');

      expect(manager.isLyricsDisabledForCurrentSong, isTrue);
      expect(manager.currentLyrics, isNull);
      expect(manager.hasKaraokeLyrics, isFalse);
    });

    test('OnlineLyricsClient.cleanArtistAndTitle splits Artist - Track from YouTube title', () {
      final res = OnlineLyricsClient.cleanArtistAndTitle('SEREBROofficial', 'SEREBRO - MI MI MI');
      expect(res.artist, equals('SEREBRO'));
      expect(res.track, equals('MI MI MI'));
    });
  });
}
