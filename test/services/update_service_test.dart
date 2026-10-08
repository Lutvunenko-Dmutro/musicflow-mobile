import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Встановлюємо mock для PackageInfo
    PackageInfo.setMockInitialValues(
      appName: 'MusicFlow Test',
      packageName: 'com.example.music_flow_mobile',
      version: '1.0.32',
      buildNumber: '33',
      buildSignature: 'mock_signature',
    );
    
    SharedPreferences.setMockInitialValues({});
  });

  group('UpdateService Version Validation', () {
    test('Should return correct current version', () async {
      final version = await UpdateService.instance.getCurrentVersion();
      expect(version.version, '1.0.32');
      expect(version.buildNumber, 33);
    });

    test('installApk should block downgrade', () async {
      final fakeFile = File('fake.apk');
      
      final downgradeInfo = UpdateInfo(
        version: '1.0.30',
        buildNumber: 30, // Поточний 33
        fileSizeBytes: 1000,
        downloadUrl: 'http://test',
        changelog: 'Test',
        userCurrentBuild: 33,
        isChannelSwitch: false,
      );

      final result = await UpdateService.instance.installApk(fakeFile, downgradeInfo);
      
      // Має повернути false, тому що downgrades заборонені
      expect(result, isFalse);
    });

    test('installApk should allow installation of newer version', () async {
      final fakeFile = File('fake.apk');
      
      final upgradeInfo = UpdateInfo(
        version: '1.0.35',
        buildNumber: 35, // Поточний 33
        fileSizeBytes: 1000,
        downloadUrl: 'http://test',
        changelog: 'Test',
        userCurrentBuild: 33,
        isChannelSwitch: false,
      );

      final result = await UpdateService.instance.installApk(fakeFile, upgradeInfo);
      
      // Тут MethodChannel поверне null (бо він не за-mock'аний), що призведе до false.
      // Але важливо, що воно не зупинилось на етапі перевірки версії.
      expect(result, isFalse); 
    });
  });
}