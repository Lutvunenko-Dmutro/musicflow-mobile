import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/utils/fft_processor.dart';

void main() {
  group('FftProcessor', () {
    setUp(() {
      FftProcessor.resetHistory();
    });

    test('processHardwareFft returns numBands elements', () {
      final dummyFftBytes = List<int>.generate(128, (i) => (i % 256));
      final result = FftProcessor.processHardwareFft(dummyFftBytes, 60);

      expect(result.length, 60);
    });

    test('processHardwareFft clamps all output values between 0.0 and 1.0', () {
      final highAmplitudeBytes = List<int>.filled(256, 255);
      final result = FftProcessor.processHardwareFft(highAmplitudeBytes, 30, amplitudeBoost: 5.0);

      for (final val in result) {
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThanOrEqualTo(1.0));
      }
    });

    test('processHardwareFft ignores DC bias in byte 0', () {
      final dcBytes = List<int>.filled(256, 0);
      dcBytes[0] = 255;
      final result = FftProcessor.processHardwareFft(dcBytes, 60);

      expect(result[0], lessThan(0.15));
      expect(result[1], lessThan(0.15));
    });

    test('processHardwareFft produces smoothly differentiated red bars', () {
      final fftBytes = List<int>.filled(512, 0);
      fftBytes[2] = 100; // Bin 1 real
      fftBytes[3] = 60;  // Bin 1 imag
      fftBytes[4] = 80;  // Bin 2 real
      fftBytes[5] = 50;  // Bin 2 imag

      final result = FftProcessor.processHardwareFft(fftBytes, 60);

      expect(result[0] != result[1] || result[1] != result[2], isTrue);
    });

    test('processHardwareFft handles empty or short byte arrays gracefully', () {
      final shortBytes = [1, 2];
      final result = FftProcessor.processHardwareFft(shortBytes, 60);

      expect(result.length, 60);
      expect(result.first, 0.02);
    });

    test('process software waveform produces valid normalized heights', () {
      final dummyWaveform = List<int>.generate(1024, (i) => (128 + (50 * sin(2 * pi * i / 32)).toInt()));
      final result = FftProcessor.process(dummyWaveform, 60);

      expect(result.length, 60);
      for (final val in result) {
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThanOrEqualTo(1.0));
      }
    });

    test('software process scales with amplitudeBoost', () {
      final waveform = List<int>.generate(1024, (i) => (128 + (60 * sin(2 * pi * i / 16)).toInt()));
      FftProcessor.resetHistory();
      final lowBoost = FftProcessor.process(waveform, 60, amplitudeBoost: 0.5);
      FftProcessor.resetHistory();
      final highBoost = FftProcessor.process(waveform, 60, amplitudeBoost: 1.2);

      // Max height with 1.2 boost must be significantly higher than with 0.5 boost
      final maxLow = lowBoost.reduce(max);
      final maxHigh = highBoost.reduce(max);
      expect(maxHigh, greaterThan(maxLow));
    });

    test('software process differentiates mid/vocal frequencies cleanly', () {
      // 1000 Hz sine wave in 44100 Hz sample rate (period ~44.1 samples)
      final midWave = List<int>.generate(1024, (i) => (128 + (80 * sin(2 * pi * 1000 * i / 44100)).toInt()));
      FftProcessor.resetHistory();
      final result = FftProcessor.process(midWave, 60);

      // Yellow/vocals (index 24..35) should peak much higher than sub-bass (index 0..5)
      final subBassAvg = (result[0] + result[1] + result[2]) / 3;
      final midPeak = result.sublist(20, 35).reduce(max);

      expect(midPeak, greaterThan(subBassAvg));
    });
  });
}
