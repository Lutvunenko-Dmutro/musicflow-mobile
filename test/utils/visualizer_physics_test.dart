import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/utils/visualizer_physics.dart';

void main() {
  group('VisualizerPhysics Unit Tests', () {
    test('Bar rises towards target according to attack rate', () {
      final targets = [1.0];
      final currents = [0.0];
      final dots = [0.0];
      final velocities = [0.0];
      bool repainted = false;

      VisualizerPhysics.updateHeights(
        barCount: 1,
        targetHeights: targets,
        currentHeights: currents,
        dotHeights: dots,
        dotVelocities: velocities,
        attack: 0.5,
        release: 0.2,
        gravity: -0.01,
        bounce: 0.05,
        onRepaintNeeded: () => repainted = true,
      );

      expect(repainted, isTrue);
      expect(currents[0], closeTo(0.5, 0.001));
      expect(dots[0], closeTo(0.5, 0.001));
    });

    test('Bar falls towards target according to release rate and dot stays up/falls by gravity', () {
      final targets = [0.0];
      final currents = [0.8];
      final dots = [0.8];
      final velocities = [0.0];
      bool repainted = false;

      VisualizerPhysics.updateHeights(
        barCount: 1,
        targetHeights: targets,
        currentHeights: currents,
        dotHeights: dots,
        dotVelocities: velocities,
        attack: 0.5,
        release: 0.25,
        gravity: -0.02,
        bounce: 0.05,
        onRepaintNeeded: () => repainted = true,
      );

      expect(repainted, isTrue);
      // current fell: 0.8 + (0.0 - 0.8) * 0.25 = 0.6
      expect(currents[0], closeTo(0.6, 0.001));
      // dot had velocity 0, gets gravity -0.02, dotHeight becomes 0.8 - 0.02 = 0.78
      expect(velocities[0], closeTo(-0.02, 0.001));
      expect(dots[0], closeTo(0.78, 0.001));
    });

    test('Dot cannot fall below the bar', () {
      final targets = [0.5];
      final currents = [0.5];
      final dots = [0.51];
      final velocities = [-0.10]; // large downward velocity

      VisualizerPhysics.updateHeights(
        barCount: 1,
        targetHeights: targets,
        currentHeights: currents,
        dotHeights: dots,
        dotVelocities: velocities,
        attack: 0.5,
        release: 0.25,
        gravity: -0.05,
        bounce: 0.0,
        onRepaintNeeded: () {},
      );

      // Dot falls but is clamped to bar height (0.5), velocity reset to 0
      expect(dots[0], closeTo(0.5, 0.001));
      expect(velocities[0], equals(0.0));
    });
  });
}
