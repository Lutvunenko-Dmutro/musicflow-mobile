import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/player/widgets/player_cover_art.dart';

class PlayerHeader extends StatefulWidget {
  final SongModel song;

  const PlayerHeader({super.key, required this.song});

  @override
  State<PlayerHeader> createState() => _PlayerHeaderState();
}

class _PlayerHeaderState extends State<PlayerHeader> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _hasHapticed = false;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      final damping = 1.0 / (1.0 + (_dragOffset.abs() / 260.0));
      _dragOffset += details.primaryDelta! * damping;

      if (_dragOffset.abs() >= 65 && !_hasHapticed) {
        HapticFeedback.selectionClick();
        _hasHapticed = true;
      } else if (_dragOffset.abs() < 50 && _hasHapticed) {
        _hasHapticed = false;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final provider = context.read<AudioProvider>();
    final velocity = details.primaryVelocity ?? 0;
    _hasHapticed = false;

    if (_dragOffset < -65 || velocity < -350) {
      if (provider.hasNext) provider.playNext();
    } else if (_dragOffset > 65 || velocity > 350) {
      if (provider.hasPrevious) provider.playPrevious();
    }

    _springAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() {
          _dragOffset = _springAnimation.value;
        });
      });

    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final rotation = (_dragOffset / 380.0) * (math.pi / 14);
    final scale = (1.0 - (_dragOffset.abs() / 1000.0)).clamp(0.92, 1.0);
    final opacity = (1.0 - (_dragOffset.abs() / 420.0)).clamp(0.5, 1.0);
    final showPrevCue = _dragOffset > 25;
    final showNextCue = _dragOffset < -25;
    final cueOpacity = (_dragOffset.abs() / 80.0).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(_dragOffset, 0.0)
                      ..rotateZ(rotation)
                      ..scale(scale),
                    child: Opacity(
                      opacity: opacity,
                      child: PlayerCoverArt(
                        song: widget.song,
                        dragOffset: _dragOffset,
                      ),
                    ),
                  ),
                  if (showPrevCue || showNextCue)
                    Positioned(
                      left: showPrevCue ? 16 : null,
                      right: showNextCue ? 16 : null,
                      child: Opacity(opacity: cueOpacity, child: _buildSwipeCueBadge(showPrevCue)),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Column(
            key: ValueKey(widget.song.id),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.song.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                widget.song.author,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white70, letterSpacing: 0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeCueBadge(bool isPrev) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1)],
      ),
      child: Icon(isPrev ? Icons.skip_previous_rounded : Icons.skip_next_rounded, color: Colors.white, size: 24),
    );
  }
}
