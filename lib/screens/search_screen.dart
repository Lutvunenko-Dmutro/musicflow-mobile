import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/local_library_provider.dart';
import '../services/youtube_service.dart';
import '../models/song_model.dart';
import '../locator.dart';
import '../widgets/custom_card.dart';
import '../widgets/search_input_card.dart';
import '../widgets/song_list_item.dart';

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

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
      _localResults = [];
    });

    // Search local library immediately (instant, no network)
    final localSongs = context.read<LocalLibraryProvider>().songs;
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
    List<SongModel> results;
    if (query.startsWith('http')) {
      results = await _ytService.resolveLink(query);
    } else {
      results = await _ytService.searchSongs(query);
    }

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
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
            ),

            const SizedBox(height: 16),

            // Local library results
            if (_localResults.isNotEmpty) ...[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.library_music, color: Theme.of(context).primaryColor, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'В бібліотеці',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_localResults.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _localResults.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final song = _localResults[index];
                        return SongListItem(
                          song: song,
                          onTap: () {
                            context.read<AudioProvider>().setQueue(_localResults, initialIndex: index);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // YouTube results
            if (hasAnyResults) ...[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.youtube_searched_for, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'YouTube',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isSearching)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text('Нічого не знайдено', style: TextStyle(color: Colors.white54)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final song = _results[index];
                          return SongListItem(
                            song: song,
                            onTap: () {
                              context.read<AudioProvider>().setQueue(_results, initialIndex: index);
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
