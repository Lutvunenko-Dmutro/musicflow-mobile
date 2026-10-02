import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/core/widgets/song_list_item.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class YoutubeSearchResults extends StatelessWidget {
  final List<SongModel> results;
  final bool isSearching;

  const YoutubeSearchResults({
    super.key,
    required this.results,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
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
          if (isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (results.isEmpty)
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
              itemCount: results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final song = results[index];
                return SongListItem(
                  song: song,
                  onTap: () {
                    context.read<AudioProvider>().setQueue(results, initialIndex: index);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
