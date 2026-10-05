class LrclibSearchResult {
  final int id;
  final String trackName;
  final String artistName;
  final String? albumName;
  final double duration;
  final String? syncedLyrics;
  final String? plainLyrics;

  const LrclibSearchResult({
    required this.id,
    required this.trackName,
    required this.artistName,
    this.albumName,
    required this.duration,
    this.syncedLyrics,
    this.plainLyrics,
  });

  bool get isKaraoke => syncedLyrics != null && syncedLyrics!.trim().isNotEmpty;
  String get bestLyrics => isKaraoke ? syncedLyrics!.trim() : (plainLyrics?.trim() ?? '');

  factory LrclibSearchResult.fromJson(Map<String, dynamic> json) {
    return LrclibSearchResult(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      trackName: json['trackName']?.toString() ?? '',
      artistName: json['artistName']?.toString() ?? '',
      albumName: json['albumName']?.toString(),
      duration: (json['duration'] is num) ? (json['duration'] as num).toDouble() : 0.0,
      syncedLyrics: json['syncedLyrics']?.toString(),
      plainLyrics: json['plainLyrics']?.toString(),
    );
  }
}
