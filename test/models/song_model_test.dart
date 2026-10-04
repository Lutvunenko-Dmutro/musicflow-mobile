import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/song_model.dart';

void main() {
  group('SongModel', () {
    test('creates a valid instance with required fields', () {
      final song = SongModel(
        id: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        author: 'Rick Astley',
        duration: const Duration(minutes: 3, seconds: 32),
        coverUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );

      expect(song.id, 'dQw4w9WgXcQ');
      expect(song.title, 'Never Gonna Give You Up');
      expect(song.author, 'Rick Astley');
      expect(song.duration.inSeconds, 212);
      expect(song.isLocal, false);
      expect(song.localPath, isNull);
      expect(song.streamUrl, isNull);
    });

    test('serializes to and from Map correctly', () {
      final original = SongModel(
        id: 'abc12345678',
        title: 'Test Track',
        author: 'Test Artist',
        duration: const Duration(seconds: 180),
        coverUrl: 'https://example.com/cover.jpg',
        isLocal: true,
        localPath: '/storage/emulated/0/Music/Test.mp3',
      );

      final map = original.toMap();
      final restored = SongModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.author, original.author);
      expect(restored.duration.inMilliseconds, original.duration.inMilliseconds);
      expect(restored.coverUrl, original.coverUrl);
      expect(restored.isLocal, original.isLocal);
      expect(restored.localPath, original.localPath);
    });

    test('copyWith updates specified fields only', () {
      final original = SongModel(
        id: 'track1',
        title: 'Original Title',
        author: 'Original Author',
        duration: const Duration(minutes: 2),
        coverUrl: 'https://cover.jpg',
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        streamUrl: 'https://rr1---sn.googlevideo.com/videoplayback?expire=123',
        isLocal: true,
        localPath: '/data/track1.m4a',
      );

      expect(updated.id, 'track1');
      expect(updated.title, 'Updated Title');
      expect(updated.author, 'Original Author');
      expect(updated.streamUrl, contains('googlevideo.com'));
      expect(updated.isLocal, true);
      expect(updated.localPath, '/data/track1.m4a');
    });
  });
}
