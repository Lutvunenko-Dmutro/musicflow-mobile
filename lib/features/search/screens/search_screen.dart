import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/features/search/widgets/search_input_card.dart';
import 'package:music_flow_mobile/features/search/widgets/local_search_results.dart';
import 'package:music_flow_mobile/features/search/widgets/youtube_search_results.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YoutubeService _ytService = locator<YoutubeService>();
  List<SongModel> _results = [];
  List<SongModel> _localResults = [];
  bool _isSearching = false;
  bool _musicOnly = true;

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
      _localResults = [];
    });

    // Search local library immediately (instant, no network)
    final localSongs = locator<LocalLibraryProvider>().songs;
    final queryLower = query.toLowerCase();
    final localMatches = localSongs.where((song) {
      return song.title.toLowerCase().contains(queryLower) ||
          song.author.toLowerCase().contains(queryLower);
    }).toList();

    if (mounted) {
      setState(() {
        _localResults = localMatches;
      });
    }

    // Then search YouTube
    try {
      List<SongModel> results;
      final isUrl = query.startsWith('http://') ||
          query.startsWith('https://') ||
          query.startsWith('www.youtube.com') ||
          query.startsWith('youtu.be');

      if (isUrl) {
        results = await _ytService.resolveLink(query);
      } else {
        results = await _ytService.searchSongs(query, musicOnly: _musicOnly);
      }

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _results = [];
        });
        
        String errorMsg = 'Помилка пошуку.';
        if (e.toString().contains('SocketException')) {
          errorMsg = 'Немає підключення до інтернету.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyResults = _localResults.isNotEmpty || _results.isNotEmpty || _isSearching;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Music Flow',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Beta 1',
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchInputCard(
              controller: _searchController,
              onSearch: _search,
              musicOnly: _musicOnly,
              onMusicOnlyChanged: (val) {
                setState(() {
                  _musicOnly = val;
                });
                if (_searchController.text.trim().isNotEmpty) {
                  _search();
                }
              },
            ),

            const SizedBox(height: 16),

            // Local library results
            if (_localResults.isNotEmpty) ...[
              LocalSearchResults(localResults: _localResults),
              const SizedBox(height: 16),
            ],

            // YouTube results
            if (hasAnyResults) ...[
              YoutubeSearchResults(results: _results, isSearching: _isSearching),
            ],
          ],
        ),
      ),
    );
  }
}
