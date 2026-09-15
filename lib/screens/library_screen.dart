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

enum SortOption {
  title,
  author,
  dateAdded,
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<SongModel> _songs = [];
  final Set<String> _selectedIds = {};
  SortOption _currentSort = SortOption.title;
  bool _isDescending = false;

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
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_currentSort) {
      case SortOption.title:
        _songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.author:
        _songs.sort((a, b) => a.author.compareTo(b.author));
        break;
      case SortOption.dateAdded:
        _songs.sort((a, b) {
          int timeA = 0;
          int timeB = 0;
          if (a.localPath != null) {
            try {
              timeA = File(a.localPath!).lastModifiedSync().millisecondsSinceEpoch;
            } catch (_) {}
          }
          if (b.localPath != null) {
            try {
              timeB = File(b.localPath!).lastModifiedSync().millisecondsSinceEpoch;
            } catch (_) {}
          }
          return timeB.compareTo(timeA); // Descending by default (newest first)
        });
        break;
    }

    if (_isDescending) {
      _songs = _songs.reversed.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? '${_selectedIds.length} вибрано' : 'Бібліотека'),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeleteSelected(context),
            )
          else ...[
            IconButton(
              icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward),
              tooltip: 'Змінити напрямок',
              onPressed: () {
                setState(() {
                  _isDescending = !_isDescending;
                  _applySorting();
                });
              },
            ),
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              onSelected: (SortOption result) {
                setState(() {
                  _currentSort = result;
                  _applySorting();
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
                const PopupMenuItem<SortOption>(
                  value: SortOption.title,
                  child: Text('За назвою'),
                ),
                const PopupMenuItem<SortOption>(
                  value: SortOption.author,
                  child: Text('За автором'),
                ),
                const PopupMenuItem<SortOption>(
                  value: SortOption.dateAdded,
                  child: Text('За часом додавання'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSongs,
            ),
          ],
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
                  selected: _selectedIds.contains(song.id),
                  selectedTileColor: Colors.redAccent.withOpacity(0.2),
                  onLongPress: () {
                    setState(() {
                      if (_selectedIds.contains(song.id)) {
                        _selectedIds.remove(song.id);
                      } else {
                        _selectedIds.add(song.id);
                      }
                    });
                  },
                  onTap: () {
                    if (isSelectionMode) {
                      setState(() {
                        if (_selectedIds.contains(song.id)) {
                          _selectedIds.remove(song.id);
                        } else {
                          _selectedIds.add(song.id);
                        }
                      });
                    } else {
                      context.read<AudioProvider>().setQueue(_songs, initialIndex: index);
                    }
                  },
                );
              },
            ),
    );
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити пісні?'),
        content: Text('Ви впевнені, що хочете видалити ${_selectedIds.length} пісень?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Видалити', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final audioProvider = context.read<AudioProvider>();
      
      for (final id in _selectedIds) {
        if (audioProvider.currentSong?.id == id) {
          await audioProvider.stop();
        }
        await DatabaseService.instance.deleteSong(id);
        
        // Also delete the physical file if it exists
        final song = _songs.firstWhere((s) => s.id == id, orElse: () => _songs.first);
        if (song.id == id && song.localPath != null) {
          final file = File(song.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      
      setState(() {
        _selectedIds.clear();
      });
      _loadSongs();
    }
  }
}
