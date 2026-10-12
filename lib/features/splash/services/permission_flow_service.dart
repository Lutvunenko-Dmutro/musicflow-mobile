import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPermissionType {
  notifications,
  visualizer,
  mediaLibrary,
  installUpdates,
}

class PermissionItemData {
  final AppPermissionType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isRequired;
  bool isGranted;

  PermissionItemData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isRequired = false,
    this.isGranted = false,
  });
}

class PermissionFlowService {
  static const String _onboardingKey = 'permissions_onboarding_completed_v1';

  static Future<bool> shouldShowPermissionsScreen() async {
    if (!Platform.isAndroid) return false;
    final prefs = await SharedPreferences.getInstance();
    final alreadyCompleted = prefs.getBool(_onboardingKey) ?? false;
    if (alreadyCompleted) return false;

    // Якщо це перший запуск або ключові дозволи не видано
    final items = await checkAllPermissions();
    final hasMissing = items.any((item) => !item.isGranted);
    return hasMissing;
  }

  static Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<List<PermissionItemData>> checkAllPermissions() async {
    final notifStatus = await Permission.notification.status;
    final micStatus = await Permission.microphone.status;
    
    // Для медіатеки на Android 13+ використовується audio, нижче — storage
    bool mediaGranted = false;
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.status;
      final storageStatus = await Permission.storage.status;
      mediaGranted = audioStatus.isGranted || storageStatus.isGranted;
    }

    final installStatus = await Permission.requestInstallPackages.status;

    return [
      PermissionItemData(
        type: AppPermissionType.notifications,
        title: '',
        subtitle: '',
        icon: Icons.notifications_active_rounded,
        isGranted: notifStatus.isGranted,
      ),
      PermissionItemData(
        type: AppPermissionType.visualizer,
        title: '',
        subtitle: '',
        icon: Icons.equalizer_rounded,
        isGranted: micStatus.isGranted,
      ),
      PermissionItemData(
        type: AppPermissionType.mediaLibrary,
        title: '',
        subtitle: '',
        icon: Icons.folder_copy_rounded,
        isGranted: mediaGranted,
      ),
      PermissionItemData(
        type: AppPermissionType.installUpdates,
        title: '',
        subtitle: '',
        icon: Icons.system_update_rounded,
        isGranted: installStatus.isGranted,
      ),
    ];
  }

  static Future<bool> requestPermission(AppPermissionType type) async {
    PermissionStatus status;
    switch (type) {
      case AppPermissionType.notifications:
        status = await Permission.notification.request();
        break;
      case AppPermissionType.visualizer:
        status = await Permission.microphone.request();
        break;
      case AppPermissionType.mediaLibrary:
        status = await Permission.audio.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        break;
      case AppPermissionType.installUpdates:
        status = await Permission.requestInstallPackages.request();
        break;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return status.isGranted;
  }
}
