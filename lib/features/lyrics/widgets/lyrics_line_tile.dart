import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';

const kLyricMotionCurve = Cubic(0.25, 0.0, 0.2, 1.0);

class LyricsLineTile extends StatelessWidget {
  final LyricsLine line;
  final bool isActive;
  final int distanceToActive;
  final double currentSec;
  final VoidCallback onTap;

  const LyricsLineTile({
    super.key,
    required this.line,
    required this.isActive,
    required this.distanceToActive,
    required this.currentSec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    final double targetOpacity;
    if (isActive) {
      targetOpacity = 1.0;
    } else if (distanceToActive <= 1) {
      targetOpacity = 0.48;
    } else if (distanceToActive <= 3) {
      targetOpacity = 0.30;
    } else {
      targetOpacity = 0.18;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: primary.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      child: AnimatedScale(
        scale: isActive ? 1.06 : 0.98,
        duration: const Duration(milliseconds: 400),
        curve: kLyricMotionCurve,
        alignment: Alignment.center,
        child: AnimatedOpacity(
          opacity: targetOpacity,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: _buildContent(context, primary),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color primary) {
    if (line.spans.isNotEmpty && isActive) {
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: line.spans.map((span) {
            final isWordSung = currentSec >= span.timeSec;
            return TextSpan(
              text: span.text,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: isWordSung ? primary : Colors.white.withValues(alpha: 0.65),
                shadows: isWordSung
                    ? [
                        Shadow(
                          color: primary.withValues(alpha: 0.6),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
            );
          }).toList(),
        ),
      );
    }

    return Text(
      line.text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isActive ? 25 : 19,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? Colors.white : Colors.white,
        shadows: isActive
            ? [
                Shadow(
                  color: primary.withValues(alpha: 0.55),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
    );
  }
}
