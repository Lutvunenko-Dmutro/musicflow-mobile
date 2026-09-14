import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

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
      version: 1,
      onCreate: _createDB,
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
  localPath TEXT
)
''');
  }

  Future<void> saveSong(SongModel song) async {
    final db = await instance.database;
    await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SongModel>> getAllSongs() async {
    final db = await instance.database;
    final result = await db.query('songs');
    return result.map((json) => SongModel.fromMap(json)).toList();
  }

  Future<void> deleteSong(String id) async {
    final db = await instance.database;
    await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
