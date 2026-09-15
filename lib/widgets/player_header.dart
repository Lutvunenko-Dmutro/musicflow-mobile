import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/song_model.dart';

class PlayerHeader extends StatelessWidget {
  final SongModel song;

  const PlayerHeader({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cover Art
          Flexible(
            flex: 5,
            child: Center(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final provider = context.read<AudioProvider>();
                  if (details.primaryVelocity! < -300) {
                    // Swipe left -> Next
                    provider.playNext();
                  } else if (details.primaryVelocity! > 300) {
                    // Swipe right -> Prev
                    provider.playPrevious();
                  }
                },
                child: Hero(
                  tag: 'cover_${song.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: song.coverBytes != null
                          ? Image.memory(
                              song.coverBytes!,
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.width * 0.8,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _fallbackCover(context),
                            )
                          : (song.coverUrl.isEmpty
                              ? _fallbackCover(context)
                              : Image.network(
                                  song.coverUrl,
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  height: MediaQuery.of(context).size.width * 0.8,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _fallbackCover(context),
                                )),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Song Info
          Flexible(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  song.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  song.author,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackCover(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Image.asset('assets/icon.png', fit: BoxFit.cover),
    );
  }
}
