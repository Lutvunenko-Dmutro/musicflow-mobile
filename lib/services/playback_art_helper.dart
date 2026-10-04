import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class PlaybackArtHelper {
  static Uri? defaultArtUri;

  static Future<void> ensureDefaultArtPrepared() async {
    if (defaultArtUri != null) return;
    try {
      final byteData = await rootBundle.load('assets/icon.png');
      final tempDir = await getApplicationDocumentsDirectory();
      final file = File('${tempDir.path}/default_cover.png');
      if (!await file.exists()) {
        await file.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
      }
      defaultArtUri = file.uri;
    } catch (e) {
      AppLogger.error('Failed to load default cover art: $e');
    }
  }

  static Future<Uri?> resolveArtUriForLocal(SongModel song) async {
    Uri? localArtUri = defaultArtUri;
    if (song.coverBytes != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final safeId = song.id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final file = File('${tempDir.path}/${safeId}_local_cover.jpg');
        if (!await file.exists()) {
          await file.writeAsBytes(song.coverBytes!);
        }
        if (await file.exists()) {
          localArtUri = file.uri;
        }
      } catch (e) {
        AppLogger.error('Failed to write local cover for notification: $e');
      }
    }
    return localArtUri;
  }

  static Future<Uri?> resolveArtUriForOnline(SongModel song) async {
    Uri? artUri = defaultArtUri;
    if (song.coverUrl.isNotEmpty) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${song.id}_cover.jpg');
        if (!await file.exists()) {
          final response = await http.get(Uri.parse(song.coverUrl));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          }
        }
        if (await file.exists()) {
          artUri = file.uri;
        }
      } catch (e) {
        AppLogger.error('Failed to download cover for notification: $e');
      }
    }
    return artUri;
  }
}
