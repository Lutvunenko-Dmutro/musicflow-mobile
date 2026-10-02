// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

/// 🎨 AppLogger — кольорове логування для Flutter
/// 
/// Використання:
///   AppLogger.info('Пісня завантажена');         // ℹ️ блакитний
///   AppLogger.success('З\'єднання встановлено'); // ✅ зелений
///   AppLogger.warning('Немає дозволу');           // ⚠️ жовтий
///   AppLogger.error('Помилка завантаження', e);  // ❌ червоний
///   AppLogger.audio('Відтворення: My Song');      // 🎧 фіолетовий
///   AppLogger.download('Прогрес: 45%');           // ⬇️ синій
///   AppLogger.visualizer('FFT розмір: 1024');     // 📊 сірий
class AppLogger {
  static const bool _verbose = false; // Зміни на true, якщо потрібні детальні логи
  
  // ANSI color codes
  static const String _reset   = '\x1B[0m';
  static const String _red     = '\x1B[31m';
  static const String _green   = '\x1B[32m';
  static const String _yellow  = '\x1B[33m';
  static const String _blue    = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan    = '\x1B[36m';
  static const String _grey    = '\x1B[90m';
  static const String _bold    = '\x1B[1m';

  // Дедуплікація: однакове повідомлення не буде показано частіше ніж раз на 5 секунд
  static const int _throttleSeconds = 5;
  static final Map<String, DateTime> _lastShown = {};

  static bool _shouldShow(String key) {
    final now = DateTime.now();
    final last = _lastShown[key];
    if (last == null || now.difference(last).inSeconds >= _throttleSeconds) {
      _lastShown[key] = now;
      return true;
    }
    return false;
  }

  static String _time() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  /// ℹ️ Загальна інформація
  static void info(String message, [String? tag]) {
    if (!_verbose) return;
    if (!_shouldShow('info:$tag:$message')) return;
    final t = tag != null ? '[$tag] ' : '';
    print('$_cyan${_bold}ℹ️  [${_time()}] $t$_reset$_cyan$message$_reset');
  }

  /// ✅ Успішна операція
  static void success(String message, [String? tag]) {
    if (!_verbose) return;
    final t = tag != null ? '[$tag] ' : '';
    print('$_green${_bold}✅ [${_time()}] $t$_reset$_green$message$_reset');
  }

  /// ⚠️ Попередження (не критично)
  static void warning(String message, [String? tag]) {
    if (!_shouldShow('warn:$tag:$message')) return;
    final t = tag != null ? '[$tag] ' : '';
    print('$_yellow${_bold}⚠️  [${_time()}] $t$_reset$_yellow$message$_reset');
  }

  /// ❌ Помилка (критично)
  static void error(String message, [Object? exception, StackTrace? stack, String? tag]) {
    final t = tag != null ? '[$tag] ' : '';
    print('$_red${_bold}❌ [${_time()}] $t$message$_reset');
    if (exception != null) {
      print('$_red   EXCEPTION: $exception$_reset');
    }
    if (stack != null) {
      print('$_red   TRACE:\n$stack$_reset');
    }
  }

  /// 🎧 Аудіо-плеєр (відтворення, пауза, перемотка)
  static void audio(String message) {
    if (!_verbose) return;
    if (!_shouldShow('audio:$message')) return;
    print('$_magenta${_bold}🎧 [${_time()}] [AUDIO]$_reset$_magenta $message$_reset');
  }

  /// ⬇️ Завантаження файлів
  static void download(String message) {
    if (!_verbose) return;
    if (!_shouldShow('dl:$message')) return;
    print('$_blue${_bold}⬇️  [${_time()}] [DOWNLOAD]$_reset$_blue $message$_reset');
  }

  /// 📊 Візуалізатор/FFT
  static void visualizer(String message) {
    if (!_verbose) return;
    if (!_shouldShow('viz:$message')) return;
    print('$_grey${_bold}📊 [${_time()}] [FFT]$_reset$_grey $message$_reset');
  }

  /// 🔵 Debug — тільки для розробки, вимикати в релізі
  static void debug(String message, [String? tag]) {
    assert(() {
      if (!_shouldShow('dbg:$tag:$message')) return true;
      final t = tag != null ? '[$tag] ' : '';
      print('$_grey${_bold}🔵 [${_time()}] $t$_reset$_grey$message$_reset');
      return true;
    }());
  }

  /// Роздільник для зручного читання
  static void separator([String? label]) {
    if (!_verbose) return;
    if (label != null) {
      print('$_grey${_bold}── $label ${'-' * (40 - label.length)}$_reset');
    } else {
      print('$_grey${'─' * 50}$_reset');
    }
  }
}
