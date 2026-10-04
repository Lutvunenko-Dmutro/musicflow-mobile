import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/main.dart';
import 'package:path/path.dart' as p;
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/models/download_info.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/utils/media_metadata_helper.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/services/download_path_resolver.dart';
import 'package:music_flow_mobile/services/download_media_scanner.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';
import 'package:music_flow_mobile/locator.dart';

export 'package:music_flow_mobile/models/download_info.dart';

class DownloadService {
  late final YoutubeService _ytService = locator<YoutubeService>();

  static Future<String> getMusicDirectory() => DownloadPathResolver.getMusicDirectory();

  final ValueNotifier<Map<String, DownloadInfo>> downloadProgress = ValueNotifier({});

  Future<void> downloadSong(SongModel song, {Future<bool> Function()? onFileExists}) async {
    AppLogger.download('Starting: ${song.title} (${song.id})');
    try {
      _updateProgress(song.id, 0.01, "З'єднання...");

      final streamInfo = await _ytService.getAudioStreamInfo(song.id);
      if (streamInfo == null) {
        throw Exception("Could not get stream info");
      }
      
      final contentLength = streamInfo.size.totalBytes;
      AppLogger.download('Stream info fetched. Size: $contentLength bytes');

      final dirPath = await getMusicDirectory();
      final safeTitle = song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
      final m4aPath = p.join(dirPath, '$safeTitle.m4a');
      final mp3Path = p.join(dirPath, '$safeTitle.mp3');
      final file = File(m4aPath);

      final shouldSkip = await _handleExistingFile(song, m4aPath, mp3Path, onFileExists);
      if (shouldSkip) return;

      AppLogger.download('Target path: $m4aPath');
      await _writeStreamToFile(song.id, streamInfo, file, contentLength);

      final coverBytes = await DownloadMediaScanner.downloadAndCropCover(song);
      if (coverBytes != null) {
        await MediaMetadataHelper.embedTags(
          filePath: m4aPath,
          title: song.title,
          artist: song.author,
          coverBytes: coverBytes,
        );
      }

      await DownloadMediaScanner.scanFileToMediaStore(m4aPath, song, coverBytes);

      final localSong = song.copyWith(
        isLocal: true,
        localPath: m4aPath,
        coverBytes: coverBytes ?? song.coverBytes,
      );
      locator<LocalLibraryProvider>().addSong(localSong);
      AppLogger.success('Memory library record updated.', 'DOWNLOAD');
      AppLogger.download('Progress 100% — FINISHED!');
    } catch (e, stack) {
      _handleDownloadError(song, e, stack);
    }
  }

  Future<bool> _handleExistingFile(
    SongModel song,
    String m4aPath,
    String mp3Path,
    Future<bool> Function()? onFileExists,
  ) async {
    String? existingPath;
    if (await File(m4aPath).exists()) {
      existingPath = m4aPath;
    } else if (await File(mp3Path).exists()) {
      existingPath = mp3Path;
    }

    if (existingPath == null) return false;

    AppLogger.info('File already exists at $existingPath.', 'DOWNLOAD');
    bool skip = true;
    if (onFileExists != null) {
      final shouldOverwrite = await onFileExists();
      skip = !shouldOverwrite;
    }

    if (skip) {
      final localSong = song.copyWith(
        isLocal: true,
        localPath: existingPath,
      );
      locator<LocalLibraryProvider>().addSong(localSong);
      _updateProgress(song.id, 1.0, "Вже завантажено");
      return true;
    }
    return false;
  }

  Future<void> _writeStreamToFile(
    String songId,
    dynamic streamInfo,
    File file,
    int contentLength,
  ) async {
    AppLogger.download('Requesting byte stream...');
    final audioStream = _ytService.getStream(streamInfo);
    int bytesDownloaded = 0;
    final sink = file.openWrite();

    int lastBytes = 0;
    DateTime lastTime = DateTime.now();
    String currentSpeedText = "Обчислення...";

    await for (final chunk in audioStream) {
      bytesDownloaded += chunk.length;
      sink.add(chunk);

      if (contentLength > 0) {
        final now = DateTime.now();
        final diff = now.difference(lastTime).inMilliseconds;

        if (diff >= 500) {
          final bytesPerSec = ((bytesDownloaded - lastBytes) / (diff / 1000)).round();
          if (bytesPerSec > 1024 * 1024) {
            currentSpeedText = '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
          } else {
            currentSpeedText = '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
          }
          lastTime = now;
          lastBytes = bytesDownloaded;
        }

        final progress = bytesDownloaded / contentLength;
        _updateProgress(songId, progress, currentSpeedText);
      }
    }
    await sink.close();
    AppLogger.success('File saved!', 'DOWNLOAD');
  }

  void _handleDownloadError(SongModel song, dynamic e, StackTrace stack) {
    AppLogger.error('Download failed', e, stack, 'DOWNLOAD');
    _updateProgress(song.id, -1.0, "Помилка");

    if (e.toString().contains('SocketException')) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Немає підключення до інтернету. Завантаження скасовано.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateProgress(String id, double progress, String speedText) {
    final current = Map<String, DownloadInfo>.from(downloadProgress.value);
    if (progress >= 1.0 || progress < 0) {
      current.remove(id);
    } else {
      current[id] = DownloadInfo(progress, speedText);
    }
    downloadProgress.value = current;
  }
}
