import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_flow_mobile/models/release_history_item.dart';
import 'package:music_flow_mobile/models/update_info.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class GithubUpdateClient {
  static const String repoOwner = 'Lutvunenko-Dmutro';
  static const String repoName = 'musicflow-mobile';
  static const String releasesUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases';

  static GithubUpdateClient? _instance;
  static GithubUpdateClient get instance => _instance ??= GithubUpdateClient();

  Future<UpdateInfo?> checkLatestRelease({
    required int currentBuildNumber,
    required String currentVersion,
    bool force = false,
  }) async {
    try {
      final uri = Uri.parse(releasesUrl);
      AppLogger.info('Запит оновлень з GitHub API: $uri', 'UPDATER');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'MusicFlow-Mobile',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        AppLogger.warning('GitHub API помилка: HTTP ${response.statusCode}', 'UPDATER');
        return null;
      }

      final dynamic decoded = json.decode(response.body);
      if (decoded is! List || decoded.isEmpty) return null;

      final latest = decoded.first as Map<String, dynamic>;
      final rawTag = latest['tag_name'] as String? ?? 'v1.0.0';
      final cleanVersion = rawTag.replaceAll(RegExp(r'^v'), '');
      final releaseName = latest['name'] as String? ?? '';
      final body = latest['body'] as String? ?? 'Оновлення з GitHub Releases';
      final remoteBuild = _extractBuildNumber(releaseName, rawTag, cleanVersion);

      final assets = (latest['assets'] as List<dynamic>?) ?? [];
      final apkAsset = assets.cast<Map<String, dynamic>>().firstWhere(
            (a) => (a['name'] as String? ?? '').endsWith('.apk'),
            orElse: () => <String, dynamic>{},
          );

      final downloadUrl = apkAsset['browser_download_url'] as String? ?? '';
      final fileSize = apkAsset['size'] as int? ?? 0;
      if (downloadUrl.isEmpty) {
        AppLogger.warning('У релізі $rawTag не знайдено APK файлу', 'UPDATER');
        return null;
      }

      final history = _parseHistory(decoded);
      final isNewer = remoteBuild > currentBuildNumber ||
          _compareVersions(cleanVersion, currentVersion) > 0;

      final shaMatch = RegExp(r'sha-?256[:\s]+([a-f0-9]{64})', caseSensitive: false).firstMatch(body);
      final sha256Hash = shaMatch?.group(1);

      if (isNewer || force) {
        AppLogger.success('Знайдено реліз на GitHub: v$cleanVersion (build $remoteBuild)', 'UPDATER');
        return UpdateInfo(
          version: cleanVersion,
          buildNumber: remoteBuild,
          changelog: body,
          downloadUrl: downloadUrl,
          fileSizeBytes: fileSize,
          history: history,
          userCurrentBuild: currentBuildNumber,
          channel: 'release',
          sha256: sha256Hash,
        );
      }
    } catch (e) {
      AppLogger.warning('Не вдалося перевірити GitHub Releases: $e', 'UPDATER');
    }
    return null;
  }

  static int _extractBuildNumber(String title, String tag, String version) {
    final matchInTitle = RegExp(r'\(build\s+(\d+)\)', caseSensitive: false).firstMatch(title);
    if (matchInTitle != null) return int.parse(matchInTitle.group(1)!);

    final matchInTag = RegExp(r'\+(\d+)').firstMatch(tag);
    if (matchInTag != null) return int.parse(matchInTag.group(1)!);

    final parts = version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length >= 3) return parts[0] * 10000 + parts[1] * 100 + parts[2];
    return 0;
  }

  static int _compareVersions(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = p1.length > p2.length ? p1.length : p2.length;
    for (int i = 0; i < maxLen; i++) {
      final num1 = i < p1.length ? p1[i] : 0;
      final num2 = i < p2.length ? p2[i] : 0;
      if (num1 != num2) return num1.compareTo(num2);
    }
    return 0;
  }

  static List<ReleaseHistoryItem> _parseHistory(List<dynamic> list) {
    final history = <ReleaseHistoryItem>[];
    for (final item in list.take(10)) {
      if (item is! Map<String, dynamic>) continue;
      final tag = item['tag_name'] as String? ?? 'v1.0.0';
      final cleanVer = tag.replaceAll(RegExp(r'^v'), '');
      final name = item['name'] as String? ?? '';
      final build = _extractBuildNumber(name, tag, cleanVer);
      history.add(ReleaseHistoryItem(
        version: cleanVer,
        buildNumber: build,
        releaseDate: (item['published_at'] as String? ?? '').split('T').first,
        changelog: item['body'] as String? ?? '',
      ));
    }
    return history;
  }
}
