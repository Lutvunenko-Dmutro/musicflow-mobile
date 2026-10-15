import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/cover_aura_geometry.dart';

void main() {
  group('CoverAuraGeometry Unit Tests', () {
    const center = Offset(100, 100);
    const size = 100.0;

    test('Computes exact circle perimeter points and perpendicular normals', () {
      final top = CoverAuraGeometry.getPoint(
        center: center,
        width: size,
        height: size,
        cornerRadius: 0,
        t: 0.0,
        isCircle: true,
      );
      expect(top.position.dx, closeTo(100.0, 0.001));
      expect(top.position.dy, closeTo(50.0, 0.001));
      expect(top.normal.dx, closeTo(0.0, 0.001));
      expect(top.normal.dy, closeTo(-1.0, 0.001));

      final right = CoverAuraGeometry.getPoint(
        center: center,
        width: size,
        height: size,
        cornerRadius: 0,
        t: 0.25,
        isCircle: true,
      );
      expect(right.position.dx, closeTo(150.0, 0.001));
      expect(right.position.dy, closeTo(100.0, 0.001));
      expect(right.normal.dx, closeTo(1.0, 0.001));
      expect(right.normal.dy, closeTo(0.0, 0.001));

      final bottom = CoverAuraGeometry.getPoint(
        center: center,
        width: size,
        height: size,
        cornerRadius: 0,
        t: 0.50,
        isCircle: true,
      );
      expect(bottom.normal.dx, closeTo(0.0, 0.001));
      expect(bottom.normal.dy, closeTo(1.0, 0.001));

      final left = CoverAuraGeometry.getPoint(
        center: center,
        width: size,
        height: size,
        cornerRadius: 0,
        t: 0.75,
        isCircle: true,
      );
      expect(left.normal.dx, closeTo(-1.0, 0.001));
      expect(left.normal.dy, closeTo(0.0, 0.001));
    });

    test('Computes strictly perpendicular normals on rounded square edges', () {
      // Top flat center at t = 0.0
      final topPoint = CoverAuraGeometry.getPoint(
        center: center,
        width: 100.0,
        height: 100.0,
        cornerRadius: 16.0,
        t: 0.0,
        isCircle: false,
      );
      expect(topPoint.normal.dx, closeTo(0.0, 0.001));
      expect(topPoint.normal.dy, closeTo(-1.0, 0.001));
      expect(topPoint.position.dy, closeTo(50.0, 0.001));

      // Right flat center at t ~ 0.25
      final rightPoint = CoverAuraGeometry.getPoint(
        center: center,
        width: 100.0,
        height: 100.0,
        cornerRadius: 16.0,
        t: 0.25,
        isCircle: false,
      );
      expect(rightPoint.normal.dx, closeTo(1.0, 0.001));
      expect(rightPoint.normal.dy, closeTo(0.0, 0.001));
      expect(rightPoint.position.dx, closeTo(150.0, 0.001));

      // Bottom flat center at t ~ 0.50
      final bottomPoint = CoverAuraGeometry.getPoint(
        center: center,
        width: 100.0,
        height: 100.0,
        cornerRadius: 16.0,
        t: 0.50,
        isCircle: false,
      );
      expect(bottomPoint.normal.dx, closeTo(0.0, 0.001));
      expect(bottomPoint.normal.dy, closeTo(1.0, 0.001));
      expect(bottomPoint.position.dy, closeTo(150.0, 0.001));

      // Left flat center at t ~ 0.75
      final leftPoint = CoverAuraGeometry.getPoint(
        center: center,
        width: 100.0,
        height: 100.0,
        cornerRadius: 16.0,
        t: 0.75,
        isCircle: false,
      );
      expect(leftPoint.normal.dx, closeTo(-1.0, 0.001));
      expect(leftPoint.normal.dy, closeTo(0.0, 0.001));
      expect(leftPoint.position.dx, closeTo(50.0, 0.001));
    });

    test('Handles zero dimensions gracefully without crashing', () {
      final p = CoverAuraGeometry.getPoint(
        center: center,
        width: 0,
        height: 0,
        cornerRadius: 0,
        t: 0.5,
      );
      expect(p.position, equals(center));
      expect(p.normal, equals(const Offset(0, -1)));
    });
  });
}
