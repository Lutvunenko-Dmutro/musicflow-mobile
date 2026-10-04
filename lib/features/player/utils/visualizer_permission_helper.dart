import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisualizerPermissionHelper {
  static bool? _cachedMicPermission;
  static bool _hasRequestedPermission = false;

  static Future<bool> checkOrRequestMicPermission() async {
    if (_cachedMicPermission == true) return true;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('mic_permission_granted') == true) {
      _cachedMicPermission = true;
      return true;
    }

    var status = await Permission.microphone.status;
    if (status.isGranted) {
      _cachedMicPermission = true;
      await prefs.setBool('mic_permission_granted', true);
      return true;
    }

    if (!_hasRequestedPermission && !status.isPermanentlyDenied) {
      _hasRequestedPermission = true;
      status = await Permission.microphone.request();
      _cachedMicPermission = status.isGranted;
      if (status.isGranted) {
        await prefs.setBool('mic_permission_granted', true);
      }
      return status.isGranted;
    }

    return false;
  }
}
