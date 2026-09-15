import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audiotags/audiotags.dart';
import '../models/song_model.dart';
import '../services/database_service.dart';
import '../providers/audio_provider.dart';
import '../utils/app_logger.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final dbSongs = await DatabaseService.instance.getAllSongs();
    
    // Scan download directory for existing files that are not in DB
    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('download_path');
    
    List<SongModel> localFolderSongs = [];
    if (customPath != null && customPath.isNotEmpty && customPath != 'За замовчуванням (Внутрішня пам\'ять)') {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        // Request storage permissions on Android to read custom external folders
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          await Permission.manageExternalStorage.request();
        }
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }

        final dbPaths = dbSongs.map((s) => s.localPath).where((path) => path != null).toSet();
        
        try {
          final files = dir.listSync();
          for (var file in files) {
            if (file is File) {
              if (file.path.endsWith('.mp3') || file.path.endsWith('.m4a')) {
                if (!dbPaths.contains(file.path)) {
                  String fileName = p.basenameWithoutExtension(file.path);
                  String title = fileName;
                  String author = 'Local File';
                  Uint8List? coverBytes;

                  try {
                    final tag = await AudioTags.read(file.path);
                    if (tag != null) {
                      title = tag.title ?? fileName;
                      author = tag.trackArtist ?? 'Local File';
                      if (tag.pictures.isNotEmpty) {
                        coverBytes = tag.pictures.first.bytes;
                      }
                    }
                  } catch (e) {
                    AppLogger.warning('Error reading ID3 tags for ${file.path}: $e', 'LIBRARY');
                  }

                  localFolderSongs.add(SongModel(
                    id: file.path, // Use path as unique ID for local files
                    title: title,
                    author: author,
                    coverUrl: '', // Empty means fallback icon
                    duration: Duration.zero,
                    isLocal: true,
                    localPath: file.path,
                    coverBytes: coverBytes,
                  ));
                }
              }
            }
          }
        } catch (e) {
          AppLogger.error('Error reading directory', e, null, 'LIBRARY');
        }
      }
    }

    setState(() {
      _songs = [...dbSongs, ...localFolderSongs];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSongs,
          ),
        ],
      ),
      body: _songs.isEmpty
          ? const Center(child: Text('Your library is empty'))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: song.coverBytes != null
                          ? Image.memory(
                              song.coverBytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/icon.png', fit: BoxFit.cover);
                              },
                            )
                          : (song.coverUrl.isEmpty
                              ? Image.asset('assets/icon.png', fit: BoxFit.cover)
                              : Image.network(
                                  song.coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset('assets/icon.png', fit: BoxFit.cover);
                                  },
                                )),
                    ),
                  ),
                  title: Text(song.title, maxLines: 1),
                  subtitle: Text(song.author, maxLines: 1),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final audioProvider = context.read<AudioProvider>();
                      if (audioProvider.currentSong?.id == song.id) {
                        await audioProvider.stop();
                      }
                      await DatabaseService.instance.deleteSong(song.id);
                      _loadSongs();
                    },
                  ),
                  onTap: () {
                    context.read<AudioProvider>().setQueue(_songs, initialIndex: index);
                  },
                );
              },
            ),
    );
  }
}
