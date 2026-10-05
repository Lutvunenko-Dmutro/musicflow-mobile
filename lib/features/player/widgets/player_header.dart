import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class PlayerHeader extends StatelessWidget {
  final SongModel song;

  const PlayerHeader({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final provider = context.read<AudioProvider>();
                  final bool isNext = provider.isPlayingNext;
                  final bool isIncoming = child.key == ValueKey(song.id);
                  
                  Offset offset;
                  if (isNext) {
                    offset = isIncoming ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
                  } else {
                    offset = isIncoming ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
                  }
                  
                  final slideAnimation = Tween<Offset>(begin: offset, end: Offset.zero).animate(animation);
                  
                  return SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: AspectRatio(
                  key: ValueKey(song.id),
                  aspectRatio: 1.0,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SmartCover(
                          song: song,
                          size: constraints.maxWidth,
                          borderRadius: 16.0,
                          heroTag: 'cover_${song.id}',
                        );
                      }
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Song Info
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final provider = context.read<AudioProvider>();
            final bool isNext = provider.isPlayingNext;
            final bool isIncoming = child.key == ValueKey(song.id);
            
            Offset offset;
            if (isNext) {
              offset = isIncoming ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
            } else {
              offset = isIncoming ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
            }
            
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: Column(
            key: ValueKey(song.id),
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                song.author,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
