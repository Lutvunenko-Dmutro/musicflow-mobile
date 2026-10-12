import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/main.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/l10n/strings_uk.dart';

void handleAudioPlaybackError(dynamic e, StackTrace stacktrace, SongModel song, Function(String) setErrorCallback) {
  final errorMsg = e.toString().replaceAll('Exception: ', '');
  if (errorMsg.contains('Loading interrupted')) {
    AppLogger.info('Завантаження аудіо скасовано або перервано іншою дією', 'AUDIO');
    return;
  }
  AppLogger.error('Exception while playing', e, stacktrace, 'AUDIO');

  final ctx = navigatorKey.currentContext;
  final l10n = (ctx != null && ctx.mounted) ? ctx.l10n : const StringsUk();
  
  if (errorMsg.contains('Локальний файл не знайдено')) {
    if (ctx != null && ctx.mounted) {
      showDialog(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: Text(l10n.missingFileTitle),
          content: Text(l10n.missingFileContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.no, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                locator<DatabaseService>().removeFromHistory(song.id);
                Navigator.pop(dialogCtx);
              },
              child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
    }
  } else if (errorMsg.contains('SocketException') || errorMsg.contains('Failed host lookup')) {
    final msg = l10n.noInternetConnection;
    setErrorCallback(msg);
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else if (errorMsg.contains('VideoUnplayableException') ||
      errorMsg.contains('unplayable') ||
      errorMsg.contains('Streams are not available')) {
    final friendly = l10n.trackBlockedYouTube;
    setErrorCallback(friendly);
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(friendly),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else {
    final msg = l10n.downloadError(errorMsg);
    setErrorCallback(msg);
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
