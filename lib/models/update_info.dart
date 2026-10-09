import 'package:music_flow_mobile/models/release_history_item.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final String downloadUrl;
  final int fileSizeBytes;
  final List<ReleaseHistoryItem> history;
  final int userCurrentBuild;
  final String channel;
  final bool isChannelSwitch;
  final String? sha256;

  const UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    required this.downloadUrl,
    required this.fileSizeBytes,
    this.history = const [],
    this.userCurrentBuild = 0,
    this.channel = 'release',
    this.isChannelSwitch = false,
    this.sha256,
  });

  factory UpdateInfo.fromJson(
    Map<String, dynamic> json, {
    int userCurrentBuild = 0,
    bool isChannelSwitch = false,
  }) {
    final rawHistory = json['history'] as List<dynamic>?;
    final historyList = rawHistory != null
        ? rawHistory
            .whereType<Map<String, dynamic>>()
            .map(ReleaseHistoryItem.fromJson)
            .toList()
        : <ReleaseHistoryItem>[];

    return UpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['buildNumber'] as int? ?? 1,
      changelog: json['changelog'] as String? ?? 'Оновлення без опису',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      history: historyList,
      userCurrentBuild: userCurrentBuild,
      channel: json['channel'] as String? ?? 'release',
      isChannelSwitch: isChannelSwitch,
      sha256: json['sha256'] as String?,
    );
  }

  List<ReleaseHistoryItem> get missedReleases {
    if (history.isEmpty) return const [];
    // Змінимо логіку "пропущених" версій: 
    // порівнюємо не по Build Number (який збився через GitHub Actions),
    // а просто повертаємо останні релізи, версія яких не співпадає з поточною.
    // Щоб не заплутувати юзера цифрами "пропущено 27", беремо максимум 5 останніх
    return history
        .where((h) => h.version != version && h.buildNumber > userCurrentBuild)
        .take(5)
        .toList();
  }
}
