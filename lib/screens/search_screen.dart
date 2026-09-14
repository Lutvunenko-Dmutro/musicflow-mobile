import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../services/youtube_service.dart';
import '../models/song_model.dart';
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
  final YoutubeService _ytService = YoutubeService();
  List<SongModel> _results = [];
  bool _isSearching = false;

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
    });

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
    _ytService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Main Action Card (Search)
            SearchInputCard(
              controller: _searchController,
              onSearch: _search,
            ),
            
            const SizedBox(height: 16),
            
            // Queue / History Header
            if (_isSearching || _results.isNotEmpty) ...[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Черга / Результати',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isSearching)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
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
