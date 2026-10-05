class ReleaseHistoryItem {
  final String version;
  final int buildNumber;
  final String releaseDate;
  final String changelog;

  const ReleaseHistoryItem({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.changelog,
  });

  factory ReleaseHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReleaseHistoryItem(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['buildNumber'] as int? ?? 1,
      releaseDate: json['releaseDate'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'buildNumber': buildNumber,
    'releaseDate': releaseDate,
    'changelog': changelog,
  };
}
