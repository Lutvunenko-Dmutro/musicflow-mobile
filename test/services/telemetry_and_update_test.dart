import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/services/update_service.dart';
import 'package:music_flow_mobile/services/github_update_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TelemetryService Tests', () {
    test('Default consent is true and can be granted or revoked', () async {
      final telemetry = TelemetryService();
      expect(await telemetry.isConsentGranted(), isTrue);

      await telemetry.setConsent(false);
      expect(await telemetry.isConsentGranted(), isFalse);

      await telemetry.setConsent(true);
      expect(await telemetry.isConsentGranted(), isTrue);
    });

    test('Server URL defaults to local IP and can be updated', () async {
      final telemetry = TelemetryService();
      expect(await telemetry.getServerUrl(), equals(TelemetryService.defaultServerUrl));

      await telemetry.setServerUrl('http://192.168.1.50:8080/');
      expect(await telemetry.getServerUrl(), equals('http://192.168.1.50:8080'));
    });

    test('sendCrashReport returns false immediately when consent is not granted', () async {
      final telemetry = TelemetryService();
      await telemetry.setConsent(false);

      final sent = await telemetry.sendCrashReport(error: 'Test error without consent');
      expect(sent, isFalse);
    });
  });

  group('UpdateService Tests', () {
    test('UpdateInfo parses correctly from json', () {
      final json = {
        'version': '1.1.0',
        'buildNumber': 3,
        'changelog': '• Оновлення караоке\n• Виправлено помилки',
        'downloadUrl': 'http://192.168.0.103:8080/api/update/download',
        'fileSizeBytes': 25000000,
      };

      final info = UpdateInfo.fromJson(json);
      expect(info.version, equals('1.1.0'));
      expect(info.buildNumber, equals(3));
      expect(info.changelog, contains('Оновлення караоке'));
      expect(info.downloadUrl, equals('http://192.168.0.103:8080/api/update/download'));
      expect(info.fileSizeBytes, equals(25000000));
      expect(info.history, isEmpty);
      expect(info.missedReleases, isEmpty);
    });

    test('UpdateInfo parses history and filters missed releases', () {
      final json = {
        'version': '1.0.8',
        'buildNumber': 8,
        'changelog': '• Зміни в 1.0.8',
        'downloadUrl': 'http://192.168.0.103:8080/api/update/download',
        'fileSizeBytes': 200000000,
        'history': [
          {
            'version': '1.0.8',
            'buildNumber': 8,
            'releaseDate': '2026-10-06',
            'changelog': '• Зміни в 1.0.8',
          },
          {
            'version': '1.0.7',
            'buildNumber': 7,
            'releaseDate': '2026-10-05',
            'changelog': '• Зміни в 1.0.7',
          },
          {
            'version': '1.0.6',
            'buildNumber': 6,
            'releaseDate': '2026-10-05',
            'changelog': '• Зміни в 1.0.6',
          },
          {
            'version': '1.0.5',
            'buildNumber': 5,
            'releaseDate': '2026-10-05',
            'changelog': '• Зміни в 1.0.5',
          },
          {
            'version': '1.0.4',
            'buildNumber': 5,
            'releaseDate': '2026-10-05',
            'changelog': '• Зміни в 1.0.4',
          },
        ],
      };

      // Користувач на build 6 (пропустив версії 7 та 8)
      final info = UpdateInfo.fromJson(json, userCurrentBuild: 6);
      expect(info.history.length, equals(5));
      // В info версія 1.0.8. Версія 1.0.7 (build 7) - пропущена.
      // 1.0.8 - не враховується, бо version == info.version.
      // 1.0.6 - build 6 (не > 6).
      // 1.0.5 - build 5 (не > 6).
      // Отже, missedReleases має бути тільки 1 (це 1.0.7).
      expect(info.missedReleases.length, equals(1));
      expect(info.missedReleases.map((r) => r.version), equals(['1.0.7']));
    });

    test('GithubUpdateClient extracts repo constants', () {
      expect(GithubUpdateClient.repoOwner, equals('Lutvunenko-Dmutro'));
      expect(GithubUpdateClient.repoName, equals('musicflow-mobile'));
      expect(GithubUpdateClient.releasesUrl, contains('api.github.com'));
    });

    test('UpdateInfo parses and preserves sha256 checksum', () {
      final json = {
        'version': '1.0.32',
        'buildNumber': 33,
        'changelog': '• Release',
        'downloadUrl': 'http://127.0.0.1:8080/api/update/download',
        'fileSizeBytes': 66000000,
        'sha256': '952476403e17f51f4846d00915409c3b142d3e6042a1dc933bf027065a5c455d',
      };
      final info = UpdateInfo.fromJson(json);
      expect(info.sha256, equals('952476403e17f51f4846d00915409c3b142d3e6042a1dc933bf027065a5c455d'));
    });
  });
}

