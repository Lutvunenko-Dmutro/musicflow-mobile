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
import '../widgets/library_list_item.dart';
import '../locator.dart';

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
  SortOption _currentSort = SortOption.dateAdded;
  bool _isDescending = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadSongs();
    locator<DatabaseService>().addListener(_loadSongs);
  }

  @override
  void dispose() {
    locator<DatabaseService>().removeListener(_loadSongs);
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSort = SortOption.values[prefs.getInt('library_sort_option') ?? SortOption.dateAdded.index];
      _isDescending = prefs.getBool('library_sort_descending') ?? false;
    });
    if (_songs.isNotEmpty) {
      _applySorting();
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('library_sort_option', _currentSort.index);
    await prefs.setBool('library_sort_descending', _isDescending);
  }

  Future<void> _loadSongs() async {
    // 1. Load from DB and show immediately
    final dbSongs = await locator<DatabaseService>().getAllSongs();
    if (mounted) {
      setState(() {
        _songs = List.from(dbSongs);
        _applySorting();
      });
    }

    // 2. Scan download directory asynchronously in the background
    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('download_path');
    
    if (customPath != null && customPath.isNotEmpty && customPath != 'За замовчуванням (Внутрішня пам\'ять)') {
      final dir = Directory(customPath);
      if (await dir.exists()) {
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
          // 1. Sync scan to instantly get all file paths
          final files = dir.listSync();
          List<SongModel> localFolderSongs = [];
          
          for (var file in files) {
            if (file is File && (file.path.endsWith('.mp3') || file.path.endsWith('.m4a'))) {
              if (!dbPaths.contains(file.path)) {
                String fileName = p.basenameWithoutExtension(file.path);
                String author = 'Local File';
                String title = fileName.replaceAll('_', ' ');
                
                if (title.contains(' - ')) {
                  final parts = title.split(' - ');
                  author = parts.first.trim();
                  title = parts.sublist(1).join(' - ').trim();
                }

                localFolderSongs.add(SongModel(
                  id: file.path,
                  title: title,
                  author: author,
                  coverUrl: '',
                  duration: Duration.zero,
                  isLocal: true,
                  localPath: file.path,
                  coverBytes: null,
                ));
              }
            }
          }

          // 2. Add them all to UI at once (instant loading)
          if (localFolderSongs.isNotEmpty && mounted) {
            setState(() {
              _songs.addAll(localFolderSongs);
              _applySorting();
            });
            
            // 3. Load ID3 tags in the background (does NOT block the UI, does NOT trigger expensive sorting)
            for (var localSong in localFolderSongs) {
              AudioTags.read(localSong.localPath!).then((tag) {
                if (tag != null && mounted) {
                  setState(() {
                    final index = _songs.indexWhere((s) => s.id == localSong.id);
                    if (index != -1) {
                      _songs[index] = _songs[index].copyWith(
                        title: (tag.title?.isNotEmpty == true) ? tag.title! : _songs[index].title,
                        author: (tag.trackArtist?.isNotEmpty == true) ? tag.trackArtist! : _songs[index].author,
                        coverBytes: tag.pictures.isNotEmpty ? tag.pictures.first.bytes : null,
                      );
                    }
                  });
                }
              }).catchError((_) {
                 // Ignore files without valid tags
              });
            }
          }
        } catch (e) {
          AppLogger.error('Error reading directory', e, null, 'LIBRARY');
        }
      }
    }
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
                _savePrefs();
              },
            ),
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              onSelected: (SortOption result) {
                setState(() {
                  _currentSort = result;
                  _applySorting();
                });
                _savePrefs();
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
                return LibraryListItem(
                  song: song,
                  isSelected: _selectedIds.contains(song.id),
                  isSelectionMode: isSelectionMode,
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
    // Capture provider before any async gap
    final audioProvider = context.read<AudioProvider>();

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

    if (confirm == true && mounted) {
      for (final id in _selectedIds) {
        if (audioProvider.currentSong?.id == id) {
          await audioProvider.stop();
        }
        await locator<DatabaseService>().deleteSong(id);
        
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
