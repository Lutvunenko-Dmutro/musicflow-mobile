import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/history_model.dart';
import 'package:music_flow_mobile/models/song_model.dart';

void main() {
  group('HistoryModel Serialization & Mapping Tests', () {
    final now = DateTime.now();

    test('Serializes to map and deserializes accurately', () {
      final historyItem = HistoryModel(
        id: 'hist_42',
        title: 'Nirvana - Smells Like Teen Spirit',
        author: 'Nirvana',
        coverUrl: 'https://cdn.example.com/nirvana.jpg',
        durationMs: 301000,
        playCount: 5,
        lastPlayedAt: now,
        coverBytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      final map = historyItem.toMap();
      expect(map['id'], equals('hist_42'));
      expect(map['duration_ms'], equals(301000));
      expect(map['play_count'], equals(5));
      expect(map['last_played_at'], equals(now.millisecondsSinceEpoch));

      final restored = HistoryModel.fromMap(map);
      expect(restored.id, equals(historyItem.id));
      expect(restored.title, equals(historyItem.title));
      expect(restored.author, equals(historyItem.author));
      expect(restored.playCount, equals(5));
      expect(restored.durationMs, equals(301000));
      expect(restored.coverBytes, equals(historyItem.coverBytes));
    });

    test('Converts from SongModel seamlessly', () {
      final originalSong = SongModel(
        id: 'song_99',
        title: 'Bohemian Rhapsody',
        author: 'Queen',
        duration: const Duration(seconds: 354),
        coverUrl: 'https://cdn.example.com/queen.jpg',
        isLocal: false,
      );

      final history = HistoryModel.fromSong(originalSong);
      expect(history.id, equals(originalSong.id));
      expect(history.title, equals(originalSong.title));
      expect(history.author, equals(originalSong.author));
      expect(history.durationMs, equals(354000));
      expect(history.playCount, equals(1));
      expect(history.coverUrl, equals(originalSong.coverUrl));
    });
  });
}
