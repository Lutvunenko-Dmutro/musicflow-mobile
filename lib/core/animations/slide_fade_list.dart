import 'package:flutter/material.dart';

class SlideFadeList extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayBase;
  final Duration duration;

  const SlideFadeList({
    super.key,
    required this.child,
    required this.index,
    this.delayBase = const Duration(milliseconds: 20),
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<SlideFadeList> createState() => _SlideFadeListState();
}

class _SlideFadeListState extends State<SlideFadeList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Add delay based on index so they appear one by one
    Future.delayed(widget.delayBase * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}
