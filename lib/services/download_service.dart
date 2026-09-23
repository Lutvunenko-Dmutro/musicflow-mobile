import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import 'database_service.dart';
import 'youtube_service.dart';
import '../utils/app_logger.dart';

import '../locator.dart';

class DownloadInfo {
  final double progress;
  final String speedText;
  DownloadInfo(this.progress, this.speedText);
}

class DownloadService {
  late final YoutubeService _ytService = locator<YoutubeService>();
  late final DatabaseService _dbService = locator<DatabaseService>();
  static const MethodChannel _scannerChannel = MethodChannel('com.example.music_flow_mobile/media_scanner');

  DownloadService();

  // Observable for progress
  final ValueNotifier<Map<String, DownloadInfo>> downloadProgress = ValueNotifier({});

  Future<void> downloadSong(SongModel song, {Future<bool> Function()? onFileExists}) async {
    AppLogger.download('Starting: ${song.title} (${song.id})');
    try {
      // 1. Mark as starting (0% progress)
      _updateProgress(song.id, 0.01, "З'єднання...");

      // 2. Get Audio Stream Info
      AppLogger.download('Fetching stream info...');
      final streamInfo = await _ytService.getAudioStreamInfo(song.id);
      if (streamInfo == null) {
        throw Exception("Could not get stream info");
      }
      
      final contentLength = streamInfo.size.totalBytes;
      AppLogger.download('Stream info fetched. Size: $contentLength bytes');

      // 3. Prepare File Path
      final prefs = await SharedPreferences.getInstance();
      String? customPath = prefs.getString('download_path');
      
      String dirPath;
      if (customPath != null && customPath.isNotEmpty) {
        dirPath = customPath;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        dirPath = dir.path;
      }
      
      final safeTitle = song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
      final m4aPath = p.join(dirPath, '$safeTitle.m4a');
      final mp3Path = p.join(dirPath, '$safeTitle.mp3');
      
      File file = File(m4aPath);
      String? existingPath;
      
      if (await file.exists()) {
        existingPath = m4aPath;
      } else if (await File(mp3Path).exists()) {
        existingPath = mp3Path;
      }
      
      if (existingPath != null) {
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
          await _dbService.saveSong(localSong);
          _updateProgress(song.id, 1.0, "Вже завантажено");
          return;
        }
      }

      AppLogger.download('Target path: $m4aPath');
      AppLogger.download('Requesting byte stream...');
      final audioStream = _ytService.getStream(streamInfo);

      // 5. Download file with progress
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
          
          if (diff >= 500) { // Update speed twice a second
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
          _updateProgress(song.id, progress, currentSpeedText);
        }
      }
      await sink.close();
      AppLogger.success('File saved!', 'DOWNLOAD');

      // 5.5 Embed ID3 tags
      Uint8List? coverBytes = song.coverBytes;
      try {
        AppLogger.download('Embedding ID3 tags...');
        if (coverBytes == null && song.coverUrl.isNotEmpty) {
          final response = await http.get(Uri.parse(song.coverUrl));
          if (response.statusCode == 200) {
            coverBytes = response.bodyBytes;
          }
        }

        await AudioTags.write(
          m4aPath,
          Tag(
            title: song.title,
            trackArtist: song.author,
            pictures: coverBytes != null
                ? [
                    Picture(
                      bytes: coverBytes,
                      mimeType: MimeType.jpeg,
                      pictureType: PictureType.coverFront,
                    )
                  ]
                : [],
          ),
        );
        AppLogger.success('ID3 tags embedded successfully!', 'DOWNLOAD');
      } catch (e) {
        AppLogger.warning('Failed to embed ID3 tags: $e', 'DOWNLOAD');
      }

      // 5.7 Trigger Android Media Scanner AFTER tags are written
      // Wait a moment to ensure OS has flushed the file to disk before scanning
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        await _scannerChannel.invokeMethod('scanFile', {'path': m4aPath});
        AppLogger.success('Media scanner triggered.', 'DOWNLOAD');
      } catch (e) {
        AppLogger.warning('Failed to trigger media scanner: $e', 'DOWNLOAD');
      }

      // 6. Update Database — include coverBytes so library shows cover art
      final localSong = song.copyWith(
        isLocal: true,
        localPath: m4aPath,
        coverBytes: coverBytes ?? song.coverBytes,
      );
      await _dbService.saveSong(localSong);
      AppLogger.success('DB record updated.', 'DOWNLOAD');
      AppLogger.download('Progress 100% — FINISHED!');

    } catch (e, stack) {
      AppLogger.error('Download failed', e, stack, 'DOWNLOAD');
      _updateProgress(song.id, -1.0, "Помилка");
    }
  }

  void _updateProgress(String id, double progress, String speedText) {
    final current = Map<String, DownloadInfo>.from(downloadProgress.value);
    if (progress >= 1.0 || progress < 0) {
      current.remove(id); // Finished or errored
    } else {
      current[id] = DownloadInfo(progress, speedText);
    }
    downloadProgress.value = current;
  }
}
