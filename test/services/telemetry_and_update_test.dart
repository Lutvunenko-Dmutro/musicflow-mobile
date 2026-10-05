import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TelemetryService Tests', () {
    test('Default consent is false and can be granted or revoked', () async {
      final telemetry = TelemetryService();
      expect(await telemetry.isConsentGranted(), isFalse);

      await telemetry.setConsent(true);
      expect(await telemetry.isConsentGranted(), isTrue);

      await telemetry.setConsent(false);
      expect(await telemetry.isConsentGranted(), isFalse);
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
    });
  });
}
