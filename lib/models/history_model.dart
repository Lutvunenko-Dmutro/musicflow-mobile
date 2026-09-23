import 'package:flutter/foundation.dart';
import 'song_model.dart';

class HistoryModel {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final int durationMs;
  final int playCount;
  final DateTime lastPlayedAt;
  final Uint8List? coverBytes;

  HistoryModel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.durationMs,
    required this.playCount,
    required this.lastPlayedAt,
    this.coverBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'duration_ms': durationMs,
      'play_count': playCount,
      'last_played_at': lastPlayedAt.millisecondsSinceEpoch,
      'coverBytes': coverBytes,
    };
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      coverUrl: map['coverUrl'],
      durationMs: map['duration_ms'] ?? 0,
      playCount: map['play_count'] ?? 1,
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(map['last_played_at'] ?? 0),
      coverBytes: map['coverBytes'],
    );
  }

  factory HistoryModel.fromSong(SongModel song) {
    return HistoryModel(
      id: song.id,
      title: song.title,
      author: song.author,
      coverUrl: song.coverUrl,
      durationMs: song.duration.inMilliseconds,
      playCount: 1,
      lastPlayedAt: DateTime.now(),
      coverBytes: song.coverBytes,
    );
  }
}
