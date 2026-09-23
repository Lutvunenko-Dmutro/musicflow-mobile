import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song_model.dart';

class DatabaseService extends ChangeNotifier {
  static Database? _database;

  DatabaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE songs (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  coverUrl TEXT NOT NULL,
  isLocal INTEGER NOT NULL,
  localPath TEXT,
  coverBytes BLOB
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add coverBytes column to existing installs
      await db.execute('ALTER TABLE songs ADD COLUMN coverBytes BLOB');
    }
  }

  Future<void> saveSong(SongModel song) async {
    final db = await database;
    await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<List<SongModel>> getAllSongs() async {
    final db = await database;
    final result = await db.query('songs');
    return result.map((json) => SongModel.fromMap(json)).toList();
  }

  Future<void> deleteSong(String id) async {
    final db = await database;
    await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }
}
