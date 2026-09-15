import 'dart:typed_data';

class SongModel {
  final String id;
  final String title;
  final String author;
  final Duration duration;
  final String coverUrl;
  final String? streamUrl;
  final bool isLocal;
  final String? localPath;
  final Uint8List? coverBytes;

  SongModel({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.coverUrl,
    this.streamUrl,
    this.isLocal = false,
    this.localPath,
    this.coverBytes,
  });

  SongModel copyWith({
    String? id,
    String? title,
    String? author,
    Duration? duration,
    String? coverUrl,
    String? streamUrl,
    bool? isLocal,
    String? localPath,
    Uint8List? coverBytes,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      isLocal: isLocal ?? this.isLocal,
      localPath: localPath ?? this.localPath,
      coverBytes: coverBytes ?? this.coverBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'duration_ms': duration.inMilliseconds,
      'coverUrl': coverUrl,
      'isLocal': isLocal ? 1 : 0,
      'localPath': localPath,
      'coverBytes': coverBytes,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      duration: Duration(milliseconds: map['duration_ms'] ?? 0),
      coverUrl: map['coverUrl'],
      isLocal: (map['isLocal'] as int) == 1,
      localPath: map['localPath'],
      coverBytes: map['coverBytes'] as Uint8List?,
    );
  }
}
