import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/media_metadata_helper.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class DownloadMediaScanner {
  static const MethodChannel _scannerChannel =
      MethodChannel('com.example.music_flow_mobile/media_scanner');

  static Future<Uint8List?> downloadAndCropCover(SongModel song) async {
    Uint8List? coverBytes = song.coverBytes;
    try {
      if (coverBytes == null && song.coverUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(song.coverUrl));
        if (response.statusCode == 200) {
          coverBytes = response.bodyBytes;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to download cover: $e', 'DOWNLOAD');
    }
    return MediaMetadataHelper.cropCoverArtToSquare(coverBytes);
  }

  static Future<void> scanFileToMediaStore(
    String m4aPath,
    SongModel song,
    Uint8List? coverBytes,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final coverBase64 = coverBytes?.map((b) => b).toList();
      await _scannerChannel.invokeMethod('scanFileWithCover', {
        'path': m4aPath,
        'title': song.title,
        'artist': song.author,
        'coverBytes': coverBase64,
      });
      AppLogger.success('Media scanner triggered with cover art.', 'DOWNLOAD');
    } catch (e) {
      AppLogger.warning('scanFileWithCover failed ($e), trying plain scan', 'DOWNLOAD');
      try {
        await _scannerChannel.invokeMethod('scanFile', {'path': m4aPath});
      } catch (e2) {
        AppLogger.error('Plain scanFile also failed', e2, null, 'DOWNLOAD');
      }
    }
  }
}
