import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/telemetry_crash_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TelemetryCrashStorage Tests', () {
    test('saveLocalCrash persists crash payload and getLastLocalCrash retrieves it', () async {
      expect(await TelemetryCrashStorage.getLastLocalCrash(), isNull);

      final crashData = {
        'error': 'FormatException: Unexpected character',
        'stackTrace': '#0 main (test.dart:10)',
        'appVersion': '1.5.0',
        'timestamp': 1718000000,
      };

      await TelemetryCrashStorage.saveLocalCrash(crashData);

      final retrieved = await TelemetryCrashStorage.getLastLocalCrash();
      expect(retrieved, isNotNull);
      expect(retrieved!['error'], equals('FormatException: Unexpected character'));
      expect(retrieved['appVersion'], equals('1.5.0'));
      expect(retrieved['timestamp'], equals(1718000000));
    });

    test('clearLastLocalCrash removes the saved crash payload', () async {
      await TelemetryCrashStorage.saveLocalCrash({'error': 'NullPointerException'});
      expect(await TelemetryCrashStorage.getLastLocalCrash(), isNotNull);

      await TelemetryCrashStorage.clearLastLocalCrash();
      expect(await TelemetryCrashStorage.getLastLocalCrash(), isNull);
    });

    test('getLastLocalCrash returns null if stored data is corrupted', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TelemetryCrashStorage.lastCrashKey, 'INVALID_JSON{[');

      final retrieved = await TelemetryCrashStorage.getLastLocalCrash();
      expect(retrieved, isNull);
    });
  });
}
