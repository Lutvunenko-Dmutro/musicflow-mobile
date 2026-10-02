import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/core/widgets/song_list_item.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class LocalSearchResults extends StatelessWidget {
  final List<SongModel> localResults;

  const LocalSearchResults({super.key, required this.localResults});

  @override
  Widget build(BuildContext context) {
    if (localResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomCard(
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
                  '${localResults.length}',
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
            itemCount: localResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final song = localResults[index];
              return SongListItem(
                song: song,
                onTap: () {
                  context.read<AudioProvider>().setQueue(localResults, initialIndex: index);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
