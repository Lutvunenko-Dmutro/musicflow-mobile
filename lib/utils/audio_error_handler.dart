import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/main.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

void handleAudioPlaybackError(dynamic e, StackTrace stacktrace, SongModel song, Function(String) setErrorCallback) {
  final errorMsg = e.toString().replaceAll('Exception: ', '');
  if (errorMsg.contains('Loading interrupted')) {
    AppLogger.info('Завантаження аудіо скасовано або перервано іншою дією', 'AUDIO');
    return;
  }
  AppLogger.error('Exception while playing', e, stacktrace, 'AUDIO');
  
  if (errorMsg.contains('Локальний файл не знайдено')) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      showDialog(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Файл відсутній'),
          content: const Text('Цей аудіофайл було видалено з пристрою. Бажаєте видалити цей запис з історії?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Ні', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                locator<DatabaseService>().removeFromHistory(song.id);
                Navigator.pop(dialogCtx);
              },
              child: const Text('Видалити', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
    }
  } else if (errorMsg.contains('SocketException') || errorMsg.contains('Failed host lookup')) {
    setErrorCallback('Немає підключення до інтернету.');
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Немає підключення до інтернету.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else if (errorMsg.contains('VideoUnplayableException') ||
      errorMsg.contains('unplayable') ||
      errorMsg.contains('Streams are not available')) {
    const friendly = 'Цей трек заблоковано на YouTube (обмеження правовласника). Спробуйте іншу версію.';
    setErrorCallback(friendly);
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text(friendly),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else {
    setErrorCallback('Помилка: $errorMsg');
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Помилка: $errorMsg'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
