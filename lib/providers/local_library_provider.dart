import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/locator.dart';

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
      final allFiles = <File>[];
      
      await for (var file in stream) {
        if (file is File) {
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.mp3' || ext == '.m4a') {
            allFiles.add(file);
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
                allFiles.add(file);
              }
            }
          }
        }
      } catch (e) {
        AppLogger.error('Failed to scan internal directory', e, null, 'LIBRARY');
      }

      // 3. Match found files with cache
      final dbService = locator<DatabaseService>();
      final cachedSongs = await dbService.getCachedLocalSongs();
      final foundPaths = <String>{};
      final unCachedPaths = <String>[];
      
      for (var file in allFiles) {
        foundPaths.add(file.path);
        final cached = cachedSongs.where((s) => s.localPath == file.path).firstOrNull;
        
        if (cached != null) {
          localSongs.add(cached);
        } else {
          localSongs.add(_createSongFromFile(file));
          unCachedPaths.add(file.path);
        }
      }

      // 4. Cleanup cache
      for (var cached in cachedSongs) {
        if (!foundPaths.contains(cached.localPath)) {
          await dbService.removeCachedLocalSong(cached.localPath!);
        }
      }
      
      _songs = localSongs;
      _isLoading = false;
      notifyListeners(); // Instantly show all files (cached + placeholders)

      // Background parse ID3 tags ONLY for uncached files
      if (unCachedPaths.isNotEmpty) {
        Future.microtask(() async {
          for (int i = 0; i < unCachedPaths.length; i++) {
            try {
              final path = unCachedPaths[i];
              final tag = await AudioTags.read(path);
              if (tag != null) {
                final idx = _songs.indexWhere((s) => s.localPath == path);
                if (idx != -1) {
                  final updatedSong = _songs[idx].copyWith(
                    title: (tag.title?.isNotEmpty == true) ? tag.title! : _songs[idx].title,
                    author: (tag.trackArtist?.isNotEmpty == true) ? tag.trackArtist! : _songs[idx].author,
                    coverBytes: tag.pictures.isNotEmpty ? tag.pictures.first.bytes : null,
                  );
                  _songs[idx] = updatedSong;
                  
                  // Save to cache
                  await dbService.cacheLocalSong(updatedSong);
                  
                  notifyListeners();
                }
              }
            } catch (e) {
              AppLogger.warning('Failed to read ID3 tag for ${unCachedPaths[i]}: $e', 'LIBRARY');
            }
            
            // Yield to event loop to keep UI smooth
            await Future.delayed(const Duration(milliseconds: 10));
          }
        });
      }
      
      
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
