import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/models/sort_option.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/features/library/widgets/library_list_item.dart';
import 'package:music_flow_mobile/features/library/widgets/library_app_bar.dart';
import 'package:music_flow_mobile/features/library/widgets/alphabet_index_bar.dart';
import 'package:music_flow_mobile/features/library/utils/library_actions_helper.dart';
import 'package:music_flow_mobile/features/library/utils/library_index_helper.dart';
import 'package:music_flow_mobile/utils/library_sorter.dart';
import 'package:music_flow_mobile/locator.dart';

export 'package:music_flow_mobile/models/sort_option.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<SongModel> _songs = [];
  final Set<String> _selectedIds = {};
  SortOption _currentSort = SortOption.dateAdded;
  bool _isDescending = false;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _onProviderUpdate();
    locator<LocalLibraryProvider>().addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    locator<LocalLibraryProvider>().removeListener(_onProviderUpdate);
    _scrollController.dispose();
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
      _currentSort = SortOption.values[prefs.getInt('library_sort_option') ?? 0];
      _isDescending = prefs.getBool('library_sort_descending') ?? false;
    });
    if (_songs.isNotEmpty) _applySorting();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('library_sort_option', _currentSort.index);
    await prefs.setBool('library_sort_descending', _isDescending);
  }

  void _applySorting() {
    LibrarySorter.sortSongs(_songs, _currentSort, _isDescending);
  }

  void _onLetterSelected(String letter) {
    final idx = LibraryIndexHelper.findFirstIndexForLetter(_songs, _currentSort, letter);
    if (idx != -1 && _scrollController.hasClients) {
      const itemHeight = 72.0;
      final target = (idx * itemHeight).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelection = _selectedIds.isNotEmpty;
    final provider = locator<LocalLibraryProvider>();
    final letters = LibraryIndexHelper.getAvailableLetters(_songs, _currentSort);

    return Scaffold(
      appBar: LibraryAppBar(
        selectedCount: _selectedIds.length,
        isSelectionMode: isSelection,
        isDescending: _isDescending,
        onClearSelection: () => setState(() => _selectedIds.clear()),
        onDeleteSelected: () => _confirmDeleteSelected(context),
        onToggleSortDirection: () {
          setState(() {
            _isDescending = !_isDescending;
            _applySorting();
          });
          _savePrefs();
        },
        onSortSelected: (sort) {
          setState(() {
            _currentSort = sort;
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
              : Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      itemCount: _songs.length,
                      itemBuilder: (context, index) => _buildSongItem(index, isSelection),
                    ),
                    if (!isSelection && letters.isNotEmpty)
                      AlphabetIndexBar(
                        availableLetters: letters,
                        onLetterSelected: _onLetterSelected,
                      ),
                  ],
                ),
    );
  }

  Widget _buildSongItem(int index, bool isSelection) {
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
              isSelectionMode: isSelection,
              onLongPress: () => _toggleSelect(song.id),
              onTap: () {
                if (isSelection) {
                  _toggleSelect(song.id);
                } else {
                  context.read<AudioProvider>().setQueue(_songs, initialIndex: index);
                }
              },
            ),
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    });
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final audio = context.read<AudioProvider>();
    final ok = await LibraryActionsHelper.confirmDeleteDialog(context, _selectedIds.length);
    if (ok && mounted) {
      final ids = List<String>.from(_selectedIds);
      setState(() {
        _deletingIds.addAll(ids);
        _selectedIds.clear();
      });
      await Future.delayed(const Duration(milliseconds: 300));
      await LibraryActionsHelper.deleteSongs(audioProvider: audio, idsToDelete: ids, songs: _songs);
      if (mounted) setState(() => _deletingIds.removeAll(ids));
    }
  }
}
