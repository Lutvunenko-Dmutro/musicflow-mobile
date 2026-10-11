import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/providers/audio/queue_manager_mixin.dart';

class AnimatedShuffleButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  final Color primary;

  const AnimatedShuffleButton({
    super.key,
    required this.isActive,
    required this.onTap,
    required this.primary,
  });

  @override
  State<AnimatedShuffleButton> createState() => _AnimatedShuffleButtonState();
}

class _AnimatedShuffleButtonState extends State<AnimatedShuffleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _rotation,
              child: ScaleTransition(
                scale: _scale,
                child: Icon(
                  Icons.shuffle_rounded,
                  color: widget.isActive ? widget.primary : Colors.grey[400],
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: widget.isActive ? 5 : 0,
              height: widget.isActive ? 5 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primary,
                boxShadow: widget.isActive
                    ? [BoxShadow(color: widget.primary.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1)]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedRepeatButton extends StatefulWidget {
  final AudioRepeatMode repeatMode;
  final VoidCallback onTap;
  final Color primary;

  const AnimatedRepeatButton({
    super.key,
    required this.repeatMode,
    required this.onTap,
    required this.primary,
  });

  @override
  State<AnimatedRepeatButton> createState() => _AnimatedRepeatButtonState();
}

class _AnimatedRepeatButtonState extends State<AnimatedRepeatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.repeatMode != AudioRepeatMode.off;
    final isOne = widget.repeatMode == AudioRepeatMode.one;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isOne ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  key: ValueKey(widget.repeatMode),
                  color: isActive ? widget.primary : Colors.grey[400],
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primary,
                boxShadow: isActive
                    ? [BoxShadow(color: widget.primary.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1)]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
