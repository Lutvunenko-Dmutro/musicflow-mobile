import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:music_flow_mobile/models/history_model.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class DatabaseService extends ChangeNotifier {
  static Database? _database;

  DatabaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_flow_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE local_songs_cache (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  coverUrl TEXT NOT NULL,
  isLocal INTEGER NOT NULL DEFAULT 1,
  localPath TEXT NOT NULL,
  coverBytes BLOB
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE history (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  coverUrl TEXT NOT NULL,
  play_count INTEGER NOT NULL DEFAULT 1,
  last_played_at INTEGER NOT NULL,
  coverBytes BLOB
)
''');

    await db.execute('''
CREATE TABLE local_songs_cache (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  coverUrl TEXT NOT NULL,
  isLocal INTEGER NOT NULL DEFAULT 1,
  localPath TEXT NOT NULL,
  coverBytes BLOB
)
''');
  }

  Future<void> cacheLocalSong(SongModel song) async {
    try {
      final db = await database;
      await db.insert(
        'local_songs_cache',
        song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      AppLogger.error('Failed to cache local song', e, null, 'DATABASE');
    }
  }

  Future<List<SongModel>> getCachedLocalSongs() async {
    try {
      final db = await database;
      final result = await db.query('local_songs_cache');
      return result.map((json) => SongModel.fromMap(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to get cached local songs', e, null, 'DATABASE');
      return [];
    }
  }

  Future<void> removeCachedLocalSong(String localPath) async {
    try {
      final db = await database;
      await db.delete('local_songs_cache', where: 'localPath = ?', whereArgs: [localPath]);
    } catch (e) {
      AppLogger.error('Failed to remove cached song', e, null, 'DATABASE');
    }
  }

  Future<void> logPlay(SongModel song) async {
    try {
      final db = await database;
      final existing = await db.query('history', where: 'id = ?', whereArgs: [song.id]);

      if (existing.isNotEmpty) {
        final currentCount = existing.first['play_count'] as int? ?? 0;
        await db.update(
          'history',
          {
            'play_count': currentCount + 1,
            'last_played_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [song.id],
        );
      } else {
        final historyEntry = HistoryModel.fromSong(song);
        await db.insert('history', historyEntry.toMap());
      }
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to log play in history', e, null, 'DATABASE');
    }
  }

  Future<List<HistoryModel>> getHistory() async {
    try {
      final db = await database;
      final result = await db.query('history', orderBy: 'last_played_at DESC');
      return result.map((json) => HistoryModel.fromMap(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to get history', e, null, 'DATABASE');
      return [];
    }
  }

  Future<void> removeFromHistory(String id) async {
    try {
      final db = await database;
      await db.delete('history', where: 'id = ?', whereArgs: [id]);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to remove from history', e, null, 'DATABASE');
    }
  }

  Future<void> clearHistory() async {
    try {
      final db = await database;
      await db.delete('history');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to clear history', e, null, 'DATABASE');
    }
  }

  Future<int> getHistoryCount() async {
    try {
      final db = await database;
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM history');
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (e) {
      AppLogger.warning('Failed to get history count: $e', 'DATABASE');
      return 0;
    }
  }

  Future<int> getDatabaseSizeBytes() async {
    try {
      final dbFolder = await getDatabasesPath();
      final path = p.join(dbFolder, 'music_flow_v3.db');
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      AppLogger.warning('Failed to get database size: $e', 'DATABASE');
    }
    return 0;
  }
}
