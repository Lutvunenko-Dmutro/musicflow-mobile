import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/update_info.dart';
import 'package:music_flow_mobile/models/release_history_item.dart';

void main() {
  group('UpdateInfo Model & SemVer Tests', () {
    test('compareSemVer correctly orders semantic versions', () {
      expect(UpdateInfo.compareSemVer('1.0.0', '1.0.0'), equals(0));
      expect(UpdateInfo.compareSemVer('v1.2.3', '1.2.3'), equals(0));
      expect(UpdateInfo.compareSemVer('1.0.1', '1.0.0'), equals(1));
      expect(UpdateInfo.compareSemVer('1.0.0', '1.0.1'), equals(-1));
      expect(UpdateInfo.compareSemVer('1.1.0', '1.0.9'), equals(1));
      expect(UpdateInfo.compareSemVer('2.0.0', '1.9.9'), equals(1));
      expect(UpdateInfo.compareSemVer('1.0', '1.0.0'), equals(0));
      expect(UpdateInfo.compareSemVer('1.0.0.1', '1.0.0'), equals(1));
    });

    test('Parses from JSON map accurately with defaults', () {
      final json = {
        'version': '2.1.0',
        'buildNumber': 45,
        'changelog': 'Bug fixes and performance improvements',
        'downloadUrl': 'https://github.com/test/app.apk',
        'fileSizeBytes': 15000000,
        'channel': 'beta',
        'sha256': 'abcdef123456',
        'history': [
          {'version': '2.0.0', 'buildNumber': 40, 'releaseDate': '2026-09-01', 'changelog': 'Major v2'}
        ],
      };

      final update = UpdateInfo.fromJson(
        json,
        userCurrentBuild: 30,
        userCurrentVersion: '1.9.0',
        isChannelSwitch: true,
      );

      expect(update.version, equals('2.1.0'));
      expect(update.buildNumber, equals(45));
      expect(update.channel, equals('beta'));
      expect(update.sha256, equals('abcdef123456'));
      expect(update.isChannelSwitch, isTrue);
      expect(update.history.length, equals(1));
    });

    test('missedReleases filters releases between userCurrentVersion and target version', () {
      final List<ReleaseHistoryItem> historyItems = [
        const ReleaseHistoryItem(version: '2.0.0', buildNumber: 20, releaseDate: '2026-01-01', changelog: 'v2.0.0'),
        const ReleaseHistoryItem(version: '1.5.0', buildNumber: 15, releaseDate: '2025-12-01', changelog: 'v1.5.0'),
        const ReleaseHistoryItem(version: '1.2.0', buildNumber: 12, releaseDate: '2025-11-01', changelog: 'v1.2.0'),
        const ReleaseHistoryItem(version: '1.0.0', buildNumber: 10, releaseDate: '2025-10-01', changelog: 'v1.0.0'),
      ];

      final update = UpdateInfo(
        version: '2.0.0',
        buildNumber: 20,
        changelog: 'Latest release',
        downloadUrl: '',
        fileSizeBytes: 0,
        history: historyItems,
        userCurrentVersion: '1.2.0',
        userCurrentBuild: 12,
      );

      final missed = update.missedReleases;
      expect(missed.length, equals(1));
      expect(missed.first.version, equals('1.5.0'));
    });
  });
}
