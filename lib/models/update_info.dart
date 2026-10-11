import 'package:music_flow_mobile/models/release_history_item.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final String downloadUrl;
  final int fileSizeBytes;
  final List<ReleaseHistoryItem> history;
  final int userCurrentBuild;
  final String userCurrentVersion;
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
    this.userCurrentVersion = '1.0.0',
    this.channel = 'release',
    this.isChannelSwitch = false,
    this.sha256,
  });

  factory UpdateInfo.fromJson(
    Map<String, dynamic> json, {
    int userCurrentBuild = 0,
    String userCurrentVersion = '1.0.0',
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
      userCurrentVersion: userCurrentVersion,
      channel: json['channel'] as String? ?? 'release',
      isChannelSwitch: isChannelSwitch,
      sha256: json['sha256'] as String?,
    );
  }

  static int compareSemVer(String v1, String v2) {
    final p1 = v1.replaceAll(RegExp(r'^v'), '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.replaceAll(RegExp(r'^v'), '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = p1.length > p2.length ? p1.length : p2.length;
    for (int i = 0; i < maxLen; i++) {
      final num1 = i < p1.length ? p1[i] : 0;
      final num2 = i < p2.length ? p2[i] : 0;
      if (num1 != num2) return num1.compareTo(num2);
    }
    return 0;
  }

  List<ReleaseHistoryItem> get missedReleases {
    if (history.isEmpty) return const [];
    // Якщо поточна версія користувача вже така сама або новіша за реліз — пропущених немає
    if (compareSemVer(userCurrentVersion, version) >= 0) return const [];

    // Реліз пропущений, якщо він СУВОРО новіший за версію користувача, але СТАРІШИЙ за цільову версію
    return history.where((h) {
      final newerThanUser = compareSemVer(h.version, userCurrentVersion) > 0;
      final olderThanTarget = compareSemVer(h.version, version) < 0;
      return newerThanUser && olderThanTarget;
    }).take(5).toList();
  }
}
