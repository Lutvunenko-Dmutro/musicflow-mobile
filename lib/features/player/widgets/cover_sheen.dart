import 'dart:math' as math;
import 'package:flutter/material.dart';

class CoverSheen extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool enableTilt;

  const CoverSheen({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.enableTilt = true,
  });

  @override
  State<CoverSheen> createState() => _CoverSheenState();
}

class _CoverSheenState extends State<CoverSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController;
  Animation<Offset>? _resetAnimation;

  Offset _touchPosition = Offset.zero;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
        if (_resetAnimation != null) {
          setState(() {
            _touchPosition = _resetAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event, BoxConstraints constraints) {
    _resetController.stop();
    _updateOffset(event.localPosition, constraints);
    setState(() => _isInteracting = true);
  }

  void _onPointerMove(PointerMoveEvent event, BoxConstraints constraints) {
    _updateOffset(event.localPosition, constraints);
  }

  void _onPointerUpOrCancel() {
    _resetAnimation = Tween<Offset>(
      begin: _touchPosition,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    ));
    _resetController.forward(from: 0.0);
    setState(() => _isInteracting = false);
  }

  void _updateOffset(Offset localPos, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (width <= 0 || height <= 0) return;

    final normX = ((localPos.dx / width) - 0.5) * 2.0;
    final normY = ((localPos.dy / height) - 0.5) * 2.0;

    setState(() {
      _touchPosition = Offset(
        normX.clamp(-1.0, 1.0),
        normY.clamp(-1.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rotX = widget.enableTilt ? -_touchPosition.dy * (math.pi / 36.0) : 0.0;
        final rotY = widget.enableTilt ? _touchPosition.dx * (math.pi / 36.0) : 0.0;

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(rotX)
          ..rotateY(rotY);

        final lightAlignX = -_touchPosition.dx * 1.2;
        final lightAlignY = -_touchPosition.dy * 1.2;

        return Listener(
          onPointerDown: (e) => _onPointerDown(e, constraints),
          onPointerMove: (e) => _onPointerMove(e, constraints),
          onPointerUp: (_) => _onPointerUpOrCancel(),
          onPointerCancel: (_) => _onPointerUpOrCancel(),
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  widget.child,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isInteracting ? 0.9 : 0.25,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(lightAlignX, lightAlignY),
                              radius: 1.1,
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
