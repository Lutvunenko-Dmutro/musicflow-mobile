import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlphabetIndexBar extends StatefulWidget {
  final List<String> availableLetters;
  final ValueChanged<String> onLetterSelected;

  const AlphabetIndexBar({
    super.key,
    required this.availableLetters,
    required this.onLetterSelected,
  });

  @override
  State<AlphabetIndexBar> createState() => _AlphabetIndexBarState();
}

class _AlphabetIndexBarState extends State<AlphabetIndexBar> {
  String? _activeLetter;
  bool _isDragging = false;

  void _handleTouch(Offset localPos, double height) {
    if (widget.availableLetters.isEmpty || height <= 0) return;

    final step = height / widget.availableLetters.length;
    final index = (localPos.dy / step).floor().clamp(0, widget.availableLetters.length - 1);
    final letter = widget.availableLetters[index];

    if (_activeLetter != letter) {
      HapticFeedback.selectionClick();
      setState(() {
        _activeLetter = letter;
      });
      widget.onLetterSelected(letter);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableLetters.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Align(
      alignment: Alignment.centerRight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barHeight = constraints.maxHeight.clamp(200.0, 520.0);

          return Stack(
            alignment: Alignment.centerRight,
            clipBehavior: Clip.none,
            children: [
              // 1. Floating preview bubble when dragging
              if (_isDragging && _activeLetter != null)
                Positioned(
                  right: 42,
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _activeLetter!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // 2. Vertical Alphabet Index Column
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (details) {
                  setState(() => _isDragging = true);
                  _handleTouch(details.localPosition, barHeight);
                },
                onVerticalDragUpdate: (details) {
                  _handleTouch(details.localPosition, barHeight);
                },
                onVerticalDragEnd: (_) {
                  setState(() => _isDragging = false);
                },
                onVerticalDragCancel: () {
                  setState(() => _isDragging = false);
                },
                onTapDown: (details) {
                  setState(() => _isDragging = true);
                  _handleTouch(details.localPosition, barHeight);
                },
                onTapUp: (_) {
                  setState(() => _isDragging = false);
                },
                child: Container(
                  height: barHeight,
                  width: 28,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? Colors.black.withValues(alpha: 0.45)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: widget.availableLetters.map((l) {
                      final isSelected = _activeLetter == l;
                      return Text(
                        l,
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 9.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? primary
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
