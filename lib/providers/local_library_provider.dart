import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import '../models/song_model.dart';
import '../utils/app_logger.dart';

class LocalLibraryProvider extends ChangeNotifier {
  List<SongModel> _songs = [];
  bool _isLoading = false;

  List<SongModel> get songs => _songs;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('download_path');
    
    // Default to public Music directory
    if (customPath == null || customPath.isEmpty || customPath == 'За замовчуванням (Внутрішня пам\'ять)') {
      customPath = '/storage/emulated/0/Music';
    }

    final dir = Directory(customPath);
    if (!await dir.exists()) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    var manageStatus = await Permission.manageExternalStorage.status;
    if (!manageStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }

    try {
      List<SongModel> localSongs = [];
      
      // 1. Scan Public Directory (e.g. /Music)
      final stream = dir.list(recursive: true);
      await for (var file in stream) {
        if (file is File) {
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.mp3' || ext == '.m4a') {
            localSongs.add(_createSongFromFile(file));
          }
        }
      }

      // 2. Scan Internal App Directory (for legacy downloaded songs)
      try {
        final internalDir = await getApplicationDocumentsDirectory();
        if (await internalDir.exists()) {
          final internalStream = internalDir.list(recursive: true);
          await for (var file in internalStream) {
            if (file is File) {
              final ext = p.extension(file.path).toLowerCase();
              if (ext == '.mp3' || ext == '.m4a') {
                localSongs.add(_createSongFromFile(file));
              }
            }
          }
        }
      } catch (e) {
        AppLogger.error('Failed to scan internal directory', e, null, 'LIBRARY');
      }

      
      _songs = localSongs;
      _isLoading = false;
      notifyListeners(); // Instantly show all files

      // Background parse ID3 tags sequentially to prevent ANR and MethodChannel flooding
      Future.microtask(() async {
        for (int i = 0; i < _songs.length; i++) {
          try {
            final path = _songs[i].localPath!;
            final tag = await AudioTags.read(path);
            if (tag != null) {
              final idx = _songs.indexWhere((s) => s.localPath == path);
              if (idx != -1) {
                _songs[idx] = _songs[idx].copyWith(
                  title: (tag.title?.isNotEmpty == true) ? tag.title! : _songs[idx].title,
                  author: (tag.trackArtist?.isNotEmpty == true) ? tag.trackArtist! : _songs[idx].author,
                  coverBytes: tag.pictures.isNotEmpty ? tag.pictures.first.bytes : null,
                );
                notifyListeners();
              }
            }
          } catch (e) {
            AppLogger.warning('Failed to read ID3 tag for ${_songs[i].localPath}: $e', 'LIBRARY');
          }
          
          // Yield to event loop to keep UI smooth
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });
      
      
    } catch (e) {
      AppLogger.error('Error loading library files', e, null, 'LIBRARY');
      _isLoading = false;
      notifyListeners();
    }
  }

  SongModel _createSongFromFile(File file) {
    String fileName = p.basenameWithoutExtension(file.path);
    String author = 'Local File';
    String title = fileName.replaceAll('_', ' ');
    
    if (title.contains(' - ')) {
      final parts = title.split(' - ');
      author = parts.first.trim();
      title = parts.sublist(1).join(' - ').trim();
    }

    return SongModel(
      id: file.path,
      title: title,
      author: author,
      coverUrl: '',
      duration: Duration.zero,
      isLocal: true,
      localPath: file.path,
      coverBytes: null,
    );
  }

  void addSong(SongModel song) {
    _songs.add(song);
    notifyListeners();
  }

  void removeSong(String id) {
    _songs.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
