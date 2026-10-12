import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Represents a point and its outward normal vector along a perimeter.
class PerimeterPoint {
  final Offset position;
  final Offset normal;

  const PerimeterPoint({
    required this.position,
    required this.normal,
  });
}

/// Precise geometric perimeter calculation for rounded squares and circles.
/// Ensures visualizer bars radiate strictly perpendicular on straight edges
/// (vertical on top/bottom, horizontal on left/right) and fan out smoothly at corners.
class CoverAuraGeometry {
  static PerimeterPoint getPoint({
    required Offset center,
    required double width,
    required double height,
    required double cornerRadius,
    required double t,
    bool isCircle = false,
  }) {
    if (isCircle) {
      final radius = width / 2.0;
      final angle = -math.pi / 2.0 + (t * 2.0 * math.pi);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      return PerimeterPoint(
        position: Offset(center.dx + radius * cosA, center.dy + radius * sinA),
        normal: Offset(cosA, sinA),
      );
    }

    final r = cornerRadius.clamp(0.0, math.min(width, height) / 2.0);
    final wFlat = width - 2.0 * r;
    final hFlat = height - 2.0 * r;
    final arcLen = (math.pi / 2.0) * r;
    final halfTop = wFlat / 2.0;

    final totalLen = 2.0 * wFlat + 2.0 * hFlat + 4.0 * arcLen;
    if (totalLen <= 0) {
      return PerimeterPoint(position: center, normal: const Offset(0, -1));
    }

    double dist = (t % 1.0) * totalLen;
    if (dist < 0) dist += totalLen;

    final cx = center.dx;
    final cy = center.dy;
    final halfW = width / 2.0;
    final halfH = height / 2.0;

    // 0. Top-Right flat half (dx: cx -> cx + halfTop, y: cy - halfH, normal: (0, -1))
    if (dist <= halfTop) {
      final u = halfTop > 0 ? dist / halfTop : 0.0;
      return PerimeterPoint(
        position: Offset(cx + u * halfTop, cy - halfH),
        normal: const Offset(0, -1),
      );
    }
    dist -= halfTop;

    // 1. Top-Right corner arc (-pi/2 -> 0)
    if (dist <= arcLen) {
      final u = arcLen > 0 ? dist / arcLen : 0.0;
      final angle = -math.pi / 2.0 + u * (math.pi / 2.0);
      final arcCenter = Offset(cx + halfW - r, cy - halfH + r);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      return PerimeterPoint(
        position: Offset(arcCenter.dx + r * cosA, arcCenter.dy + r * sinA),
        normal: Offset(cosA, sinA),
      );
    }
    dist -= arcLen;

    // 2. Right flat (dy: cy - halfH + r -> cy + halfH - r, normal: (1, 0))
    if (dist <= hFlat) {
      final u = hFlat > 0 ? dist / hFlat : 0.0;
      return PerimeterPoint(
        position: Offset(cx + halfW, cy - halfH + r + u * hFlat),
        normal: const Offset(1, 0),
      );
    }
    dist -= hFlat;

    // 3. Bottom-Right corner arc (0 -> pi/2)
    if (dist <= arcLen) {
      final u = arcLen > 0 ? dist / arcLen : 0.0;
      final angle = u * (math.pi / 2.0);
      final arcCenter = Offset(cx + halfW - r, cy + halfH - r);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      return PerimeterPoint(
        position: Offset(arcCenter.dx + r * cosA, arcCenter.dy + r * sinA),
        normal: Offset(cosA, sinA),
      );
    }
    dist -= arcLen;

    // 4. Bottom flat (dx: cx + halfW - r -> cx - halfW + r, normal: (0, 1))
    if (dist <= wFlat) {
      final u = wFlat > 0 ? dist / wFlat : 0.0;
      return PerimeterPoint(
        position: Offset(cx + halfW - r - u * wFlat, cy + halfH),
        normal: const Offset(0, 1),
      );
    }
    dist -= wFlat;

    // 5. Bottom-Left corner arc (pi/2 -> pi)
    if (dist <= arcLen) {
      final u = arcLen > 0 ? dist / arcLen : 0.0;
      final angle = math.pi / 2.0 + u * (math.pi / 2.0);
      final arcCenter = Offset(cx - halfW + r, cy + halfH - r);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      return PerimeterPoint(
        position: Offset(arcCenter.dx + r * cosA, arcCenter.dy + r * sinA),
        normal: Offset(cosA, sinA),
      );
    }
    dist -= arcLen;

    // 6. Left flat (dy: cy + halfH - r -> cy - halfH + r, normal: (-1, 0))
    if (dist <= hFlat) {
      final u = hFlat > 0 ? dist / hFlat : 0.0;
      return PerimeterPoint(
        position: Offset(cx - halfW, cy + halfH - r - u * hFlat),
        normal: const Offset(-1, 0),
      );
    }
    dist -= hFlat;

    // 7. Top-Left corner arc (pi -> 3*pi/2)
    if (dist <= arcLen) {
      final u = arcLen > 0 ? dist / arcLen : 0.0;
      final angle = math.pi + u * (math.pi / 2.0);
      final arcCenter = Offset(cx - halfW + r, cy - halfH + r);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      return PerimeterPoint(
        position: Offset(arcCenter.dx + r * cosA, arcCenter.dy + r * sinA),
        normal: Offset(cosA, sinA),
      );
    }
    dist -= arcLen;

    // 8. Top-Left flat half (dx: cx - halfW + r -> cx, normal: (0, -1))
    final u = halfTop > 0 ? (dist / halfTop).clamp(0.0, 1.0) : 0.0;
    return PerimeterPoint(
      position: Offset(cx - halfW + r + u * halfTop, cy - halfH),
      normal: const Offset(0, -1),
    );
  }
}
