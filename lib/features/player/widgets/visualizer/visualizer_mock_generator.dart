import 'dart:math';

class VisualizerMockGenerator {
  double _phase = 0.0;

  List<int> generateNextFrame() {
    _phase += 0.18;
    return List<int>.generate(128, (i) {
      final wave1 = sin(_phase + (i * 0.12));
      final wave2 = cos((_phase * 0.7) + (i * 0.25));
      final beat = (sin(_phase * 0.6) > 0.45) ? 65.0 : 0.0;
      return ((wave1 * 35) + (wave2 * 20) + beat + 15).clamp(-128, 127).toInt();
    });
  }
}
