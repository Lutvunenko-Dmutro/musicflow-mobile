// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps
import 'dart:developer' as developer;

/// 🎨 AppLogger — кольорове структуроване логування для Flutter
class AppLogger {
  static const bool _verbose = true; // Увімкнено для повної видимості дій у плеєрі
  
  // ANSI коди кольорів для терміналу
  static const String _reset   = '\x1B[0m';
  static const String _red     = '\x1B[31m';
  static const String _green   = '\x1B[32m';
  static const String _yellow  = '\x1B[33m';
  static const String _blue    = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan    = '\x1B[36m';
  static const String _grey    = '\x1B[90m';
  static const String _bold    = '\x1B[1m';

  static final Map<String, DateTime> _lastShown = {};

  static bool _shouldShow(String key, int throttleMs) {
    if (throttleMs <= 0) return true;
    final now = DateTime.now();
    final last = _lastShown[key];
    if (last == null || now.difference(last).inMilliseconds >= throttleMs) {
      _lastShown[key] = now;
      return true;
    }
    return false;
  }

  static String _time() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  static void _log(String icon, String color, String message, [String? tag, int throttleMs = 0]) {
    if (!_verbose) return;
    if (throttleMs > 0 && !_shouldShow('$tag:$message', throttleMs)) return;
    final t = tag != null ? '[$tag] ' : '';
    print('$color$_bold$icon [${_time()}] $t$_reset$color$message$_reset');
    developer.log(message, name: tag ?? 'APP');
  }

  /// ℹ️ Загальна інформація
  static void info(String message, [String? tag]) {
    _log('ℹ️ ', _cyan, message, tag);
  }

  /// ✅ Успішна дія
  static void success(String message, [String? tag]) {
    _log('✅', _green, message, tag);
  }

  /// ⚠️ Попередження
  static void warning(String message, [String? tag]) {
    _log('⚠️ ', _yellow, message, tag, 1000);
  }

  /// ❌ Помилка
  static void error(String message, [Object? exception, StackTrace? stack, String? tag]) {
    final t = tag != null ? '[$tag] ' : '';
    print('$_red$_bold❌ [${_time()}] $t$message$_reset');
    if (exception != null) {
      print('$_red   EXCEPTION: $exception$_reset');
    }
    if (stack != null) {
      print('$_red   TRACE:\n$stack$_reset');
    }
    developer.log(message, name: tag ?? 'ERROR', error: exception, stackTrace: stack);
  }

  /// 🎧 Аудіо-плеєр (відтворення, зміна треку)
  static void audio(String message) {
    _log('🎧', _magenta, message, 'AUDIO');
  }

  /// ⬇️ Завантаження файлів
  static void download(String message) {
    _log('⬇️ ', _blue, message, 'DOWNLOAD', 500);
  }

  /// 📊 Візуалізатор/FFT
  static void visualizer(String message) {
    _log('📊', _grey, message, 'FFT', 2000);
  }

  /// 🔀 Crossfade
  static void crossfade(String message) {
    _log('🔀', _magenta, message, 'CROSSFADE');
  }

  /// 🔵 Debug
  static void debug(String message, [String? tag]) {
    assert(() {
      _log('🔵', _grey, message, tag ?? 'DEBUG');
      return true;
    }());
  }

  /// Розділювач
  static void separator([String? label]) {
    if (!_verbose) return;
    if (label != null) {
      print('$_grey$_bold── $label ${'-' * (40 - label.length)}$_reset');
    } else {
      print('$_grey${'─' * 50}$_reset');
    }
  }
}
