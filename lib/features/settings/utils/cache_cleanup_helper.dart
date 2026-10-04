import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class CacheSizeData {
  final int tempBytes;
  final int tempFilesCount;
  final int lyricsBytes;
  final int lyricsCount;
  final int dbBytes;
  final int historyCount;

  CacheSizeData({
    required this.tempBytes,
    required this.tempFilesCount,
    required this.lyricsBytes,
    required this.lyricsCount,
    required this.dbBytes,
    required this.historyCount,
  });

  int get totalBytes => tempBytes + lyricsBytes + dbBytes;
}

class CacheCleanupHelper {
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 Б';
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} МБ';
  }

  static Future<bool> confirmAction({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Очистити', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<CacheSizeData> calculateSizes() async {
    int tempBytes = 0;
    int tempCount = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync(recursive: true)) {
          if (entity is File) {
            tempBytes += entity.lengthSync();
            tempCount++;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Не вдалося вирахувати розмір temp: $e', 'SETTINGS');
    }

    int lyricsBytes = 0;
    int lyricsCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith('lyrics_cache_')) {
          lyricsCount++;
          final val = prefs.getString(key);
          if (val != null) lyricsBytes += val.length;
        }
      }
    } catch (e) {
      AppLogger.warning('Не вдалося вирахувати розмір lyrics: $e', 'SETTINGS');
    }

    int dbBytes = 0;
    int historyCount = 0;
    try {
      final dbService = locator<DatabaseService>();
      dbBytes = await dbService.getDatabaseSizeBytes();
      historyCount = await dbService.getHistoryCount();
    } catch (e) {
      AppLogger.warning('Не вдалося вирахувати розмір БД/історії: $e', 'SETTINGS');
    }

    return CacheSizeData(
      tempBytes: tempBytes,
      tempFilesCount: tempCount,
      lyricsBytes: lyricsBytes,
      lyricsCount: lyricsCount,
      dbBytes: dbBytes,
      historyCount: historyCount,
    );
  }

  static Future<void> clearTempFiles() async {
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      for (final entity in tempDir.listSync()) {
        try {
          entity.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  static Future<void> clearLyricsCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('lyrics_cache_')) {
        await prefs.remove(key);
      }
    }
  }

  static Future<void> clearDatabaseCache() async {
    final db = await locator<DatabaseService>().database;
    await db.delete('local_songs_cache');
  }

  static Future<void> clearHistory() async {
    await locator<DatabaseService>().clearHistory();
  }

  static Future<void> clearAll() async {
    await clearTempFiles();
    await clearLyricsCache();
    await clearDatabaseCache();
  }
}
