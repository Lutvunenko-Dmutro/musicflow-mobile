import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_flow_mobile/main.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/utils/media_metadata_helper.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

import 'package:music_flow_mobile/locator.dart';

class DownloadInfo {
  final double progress;
  final String speedText;
  DownloadInfo(this.progress, this.speedText);
}

class DownloadService {
  late final YoutubeService _ytService = locator<YoutubeService>();
  static const MethodChannel _scannerChannel = MethodChannel('com.example.music_flow_mobile/media_scanner');

  DownloadService();

  /// Отримати надійну директорію для збереження та читання аудіофайлів
  static Future<String> getMusicDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('download_path');
    
    if (customPath != null &&
        customPath.isNotEmpty &&
        customPath != 'За замовчуванням (Внутрішня пам\'ять)') {
      final customDir = Directory(customPath);
      if (customDir.existsSync()) return customPath;
    }

    // 1. Стандартна системна папка Music на Android
    const defaultPath = '/storage/emulated/0/Music';
    final defaultDir = Directory(defaultPath);
    if (defaultDir.existsSync()) {
      return defaultPath;
    }

    // 2. Якщо стандартний шлях недоступний (інший профіль, планшет або SD-карта)
    if (Platform.isAndroid) {
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
        if (extDirs != null && extDirs.isNotEmpty) {
          return extDirs.first.path;
        }
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final musicDir = Directory(p.join(extDir.path, 'Music'));
          if (!musicDir.existsSync()) musicDir.createSync(recursive: true);
          return musicDir.path;
        }
      } catch (e) {
        AppLogger.warning('Не вдалося отримати external music storage: $e', 'DOWNLOAD');
      }
    }

    // 3. Fallback у документи додатку
    final docsDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory(p.join(docsDir.path, 'Music'));
    if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
    return fallbackDir.path;
  }

  // Observable for progress
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

      final coverBytes = await _downloadAndCropCover(song);
      if (coverBytes != null) {
        await MediaMetadataHelper.embedTags(
          filePath: m4aPath,
          title: song.title,
          artist: song.author,
          coverBytes: coverBytes,
        );
      }

      await _scanFileToMediaStore(m4aPath, song, coverBytes);

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

  Future<Uint8List?> _downloadAndCropCover(SongModel song) async {
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

  Future<void> _scanFileToMediaStore(
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
