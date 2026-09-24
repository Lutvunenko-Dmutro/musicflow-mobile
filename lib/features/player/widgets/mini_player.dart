import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/screens/player_screen.dart';
import 'package:music_flow_mobile/features/player/widgets/mini_player_progress.dart';
import 'package:music_flow_mobile/features/player/widgets/mini_player_controls.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            const MiniPlayerProgress(),
            
            Expanded(
              child: SafeArea(
                left: true,
                right: true,
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Cover Art with rounded corners
                      Hero(
                        tag: 'cover_${song.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.coverBytes != null
                            ? Image.memory(
                                  song.coverBytes!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset('assets/icon.png', width: 48, height: 48, fit: BoxFit.cover),
                                )
                              : (song.coverUrl.isEmpty
                                  ? Image.asset('assets/icon.png', width: 48, height: 48, fit: BoxFit.cover)
                                : Image.network(
                                    song.coverUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset('assets/icon.png', width: 48, height: 48, fit: BoxFit.cover),
                                  )),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Title and Author
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[400], 
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const MiniPlayerControls(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
