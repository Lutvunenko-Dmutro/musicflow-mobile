import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/features/library/widgets/library_list_item.dart';
import 'package:music_flow_mobile/features/library/widgets/library_app_bar.dart';
import 'package:music_flow_mobile/utils/library_sorter.dart';
import 'package:music_flow_mobile/locator.dart';

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
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _onProviderUpdate(); // Initial load
    locator<LocalLibraryProvider>().addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    locator<LocalLibraryProvider>().removeListener(_onProviderUpdate);
    super.dispose();
  }

  void _onProviderUpdate() {
    if (mounted) {
      setState(() {
        _songs = List.from(locator<LocalLibraryProvider>().songs);
        _applySorting();
      });
    }
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

  void _applySorting() {
    LibrarySorter.sortSongs(_songs, _currentSort, _isDescending);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = _selectedIds.isNotEmpty;
    final provider = locator<LocalLibraryProvider>();

    return Scaffold(
      appBar: LibraryAppBar(
        selectedCount: _selectedIds.length,
        isSelectionMode: isSelectionMode,
        isDescending: _isDescending,
        onClearSelection: () {
          setState(() {
            _selectedIds.clear();
          });
        },
        onDeleteSelected: () => _confirmDeleteSelected(context),
        onToggleSortDirection: () {
          setState(() {
            _isDescending = !_isDescending;
            _applySorting();
          });
          _savePrefs();
        },
        onSortSelected: (SortOption result) {
          setState(() {
            _currentSort = result;
            _applySorting();
          });
          _savePrefs();
        },
        onRefresh: () => provider.init(),
      ),
      body: provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(child: Text('Ваша бібліотека порожня'))
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final isDeleting = _deletingIds.contains(song.id);
                    
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isDeleting
                          ? const SizedBox(width: double.infinity, height: 0)
                          : LibraryListItem(
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
                            ),
                    );
                  },
                ),
    );
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final audioProvider = context.read<AudioProvider>();
    final libProvider = locator<LocalLibraryProvider>();

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
      final idsToDelete = List<String>.from(_selectedIds);
      
      setState(() {
        _deletingIds.addAll(idsToDelete);
        _selectedIds.clear();
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      for (final id in idsToDelete) {
        if (audioProvider.currentSong?.id == id) {
          await audioProvider.stop();
        }
        
        final song = _songs.firstWhere((s) => s.id == id, orElse: () => _songs.first);
        if (song.id == id && song.localPath != null) {
          final file = File(song.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        
        libProvider.removeSong(id);
      }
      
      setState(() {
        _deletingIds.removeAll(idsToDelete);
      });
    }
  }
}
