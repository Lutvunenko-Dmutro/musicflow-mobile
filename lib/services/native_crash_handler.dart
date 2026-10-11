import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class NativeCrashHandler {
  static const MethodChannel _nativeCrashChannel =
      MethodChannel('com.example.music_flow_mobile/native_crash');

  /// Перевіряє, чи не стався нативний збій Android перед попереднім перезапуском
  static Future<void> checkAndSendPendingNativeCrash() async {
    if (!Platform.isAndroid) return;
    try {
      final pending = await _nativeCrashChannel.invokeMethod<String>('getPendingNativeCrash');
      if (pending != null && pending.isNotEmpty) {
        AppLogger.warning('Знайдено нативний звіт про збій Android! Відправляємо...', 'TELEMETRY');
        final service = TelemetryService.instance;
        final base = await service.getServerUrl();
        final url = Uri.parse('$base/api/telemetry/crash-report');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: pending,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          AppLogger.info('Нативний звіт про збій успішно доставлено на сервер!', 'TELEMETRY');
          await _nativeCrashChannel.invokeMethod('clearPendingNativeCrash');
        }
      }
    } catch (e) {
      AppLogger.warning('Не вдалося перевірити нативний звіт: $e', 'TELEMETRY');
    }
  }

  static void init() {
    final service = TelemetryService.instance;
    checkAndSendPendingNativeCrash();

    AppLogger.onErrorListener = (msg, ex, stack, tag) {
      service.sendCrashReport(
        error: '$msg ${ex != null ? "($ex)" : ""}',
        stack: stack,
        extra: {'source': 'AppLogger', 'tag': tag ?? 'GENERAL'},
      );
    };

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      service.sendCrashReport(
        error: details.exceptionAsString(),
        stack: details.stack,
        extra: {'source': 'FlutterError'},
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      service.sendCrashReport(
        error: error.toString(),
        stack: stack,
        extra: {'source': 'PlatformDispatcher'},
      );
      return true;
    };
  }
}
