import 'dart:math';

/// Generates realistic synthetic music audio frames (128 samples PCM).
/// Simulates 128 BPM electronic music: 4-on-the-floor Kick, 808 Bass, Snare, Hi-hats, and Lead Synth.
class VisualizerMockGenerator {
  int _step = 0;
  double _phaseKick = 0.0;
  double _phaseBass = 0.0;
  double _phaseSynth = 0.0;
  double _phaseHiHat = 0.0;
  final Random _rng = Random(42);

  List<int> generateNextFrame() {
    _step = (_step + 1) % 64; // 64-step loop (2 bars of 4/4 music)

    final int beat = _step % 8; // 8 sub-steps per beat
    final bool isKickBeat = (beat == 0); // 4-on-the-floor kick
    final bool isSnareBeat = (_step % 16 == 8); // Snare on beats 2 and 4
    final bool isHatBeat = (_step % 2 == 0); // 16th note hi-hats
    final bool isOpenHat = (beat == 4); // Off-beat open hat

    // Decay envelopes (0.0 to 1.0)
    final double kickEnv = isKickBeat ? 1.0 : max(0.0, 1.0 - (beat / 4.0));
    final double snareEnv = isSnareBeat ? 1.0 : max(0.0, 1.0 - ((_step % 16 - 8).abs() / 4.0));
    final double hatEnv = isOpenHat ? 0.75 : (isHatBeat ? 0.45 : 0.0);

    // 808 Bass note changes every 16 steps (A -> F -> G -> E)
    final double bassFreq = switch (_step ~/ 16) {
      0 => 55.0,  // A1
      1 => 43.6,  // F1
      2 => 49.0,  // G1
      _ => 41.2,  // E1
    };

    // Lead synth note progression
    final double synthFreq = 440.0 + sin(_step * 0.25) * 180.0;

    return List<int>.generate(128, (i) {
      final double t = i / 128.0;

      // 1. Kick: frequency sweep 140Hz -> 45Hz with exponential punch
      final double kickFreq = 45.0 + (95.0 * kickEnv);
      _phaseKick += (kickFreq / 44100.0) * 2.0 * pi;
      final double kickSample = sin(_phaseKick) * kickEnv * 65.0;

      // 2. 808 Sub-bass: rich harmonics
      _phaseBass += (bassFreq / 44100.0) * 2.0 * pi;
      final double bassSample = (sin(_phaseBass) + 0.35 * sin(_phaseBass * 2.0)) * 42.0;

      // 3. Snare: burst of mid-frequency noise + 220Hz body
      final double noise = (_rng.nextDouble() * 2.0 - 1.0) * 45.0;
      final double snareBody = sin(t * 18.0) * 25.0;
      final double snareSample = (noise + snareBody) * snareEnv;

      // 4. Hi-hat: high frequency sizzle
      _phaseHiHat += (9500.0 / 44100.0) * 2.0 * pi;
      final double hatNoise = (_rng.nextDouble() - 0.5) * 28.0;
      final double hatSample = (sin(_phaseHiHat) * 14.0 + hatNoise) * hatEnv;

      // 5. Synth Lead: vibrant chords in vocal range
      _phaseSynth += (synthFreq / 44100.0) * 2.0 * pi;
      final double synthSample = sin(_phaseSynth) * 28.0;

      final double mixed = kickSample + bassSample + snareSample + hatSample + synthSample;
      return mixed.clamp(-128.0, 127.0).toInt();
    });
  }
}
