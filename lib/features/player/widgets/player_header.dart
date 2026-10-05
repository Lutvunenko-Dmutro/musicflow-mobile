import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class PlayerHeader extends StatefulWidget {
  final SongModel song;

  const PlayerHeader({super.key, required this.song});

  @override
  State<PlayerHeader> createState() => _PlayerHeaderState();
}

class _PlayerHeaderState extends State<PlayerHeader> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta! * 0.75;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final provider = context.read<AudioProvider>();
    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset < -60 || velocity < -350) {
      if (provider.hasNext) {
        provider.playNext();
      }
    } else if (_dragOffset > 60 || velocity > 350) {
      if (provider.hasPrevious) {
        provider.playPrevious();
      }
    }

    _springAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _springAnimation.value;
        });
      });

    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.opaque,
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Opacity(
                  opacity: (1.0 - (_dragOffset.abs() / 400.0)).clamp(0.4, 1.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SmartCover(
                        song: widget.song,
                        size: 320,
                        borderRadius: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Column(
            key: ValueKey(widget.song.id),
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.song.title,
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
                widget.song.author,
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
