import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/utils/music_search_filter.dart';

void main() {
  group('MusicSearchFilter', () {
    test('identifies normal music track as music', () {
      final isMusic = MusicSearchFilter.isMusic(
        title: 'SKOFKA - ЧУТИ ГІМН',
        author: 'SKOFKA',
        duration: const Duration(minutes: 2, seconds: 34),
      );
      expect(isMusic, isTrue);
    });

    test('identifies topic channels as music', () {
      final isMusic = MusicSearchFilter.isMusic(
        title: 'Random Track Name',
        author: 'Eminem - Topic',
        duration: const Duration(minutes: 4, seconds: 12),
      );
      expect(isMusic, isTrue);
    });

    test('rejects videos exceeding 10 minutes', () {
      final isMusic = MusicSearchFilter.isMusic(
        title: 'Some Potap Compilation',
        author: 'Music Channel',
        duration: const Duration(minutes: 15),
      );
      expect(isMusic, isFalse);
    });

    test('rejects videos shorter than 40 seconds', () {
      final isMusic = MusicSearchFilter.isMusic(
        title: 'Tiktok funny sound',
        author: 'User123',
        duration: const Duration(seconds: 15),
      );
      expect(isMusic, isFalse);
    });

    test('rejects interviews, podcasts and news', () {
      expect(
        MusicSearchFilter.isMusic(
          title: 'Потап – велике інтерв\'ю про шоубізнес',
          author: 'вДудь',
          duration: const Duration(minutes: 8),
        ),
        isFalse,
      );

      expect(
        MusicSearchFilter.isMusic(
          title: 'Новини ТСН: Головні події дня',
          author: 'ТСН',
          duration: const Duration(minutes: 5),
        ),
        isFalse,
      );

      expect(
        MusicSearchFilter.isMusic(
          title: 'Подкаст про життя і музику #5',
          author: 'Some Guy',
          duration: const Duration(minutes: 10),
        ),
        isFalse,
      );

      expect(
        MusicSearchFilter.isMusic(
          title: 'Реакція на новий кліп Потапа',
          author: 'Reaction King',
          duration: const Duration(minutes: 6),
        ),
        isFalse,
      );
    });

    test('rejects livestreams', () {
      final isMusic = MusicSearchFilter.isMusic(
        title: 'Lofi hip hop radio - beats to relax',
        author: 'Lofi Girl',
        duration: const Duration(hours: 100),
        isLive: true,
      );
      expect(isMusic, isFalse);
    });

    test('parses duration strings correctly', () {
      expect(MusicSearchFilter.parseDuration('3:45'), const Duration(minutes: 3, seconds: 45));
      expect(MusicSearchFilter.parseDuration('1:02:15'), const Duration(hours: 1, minutes: 2, seconds: 15));
      expect(MusicSearchFilter.parseDuration('50'), const Duration(seconds: 50));
      expect(MusicSearchFilter.parseDuration(''), Duration.zero);
    });
  });
}
