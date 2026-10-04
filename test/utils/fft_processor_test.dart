import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/utils/fft_processor.dart';

void main() {
  group('FftProcessor', () {
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

    test('processHardwareFft handles empty or short byte arrays gracefully', () {
      final shortBytes = [1, 2];
      final result = FftProcessor.processHardwareFft(shortBytes, 60);

      expect(result.length, 60);
      expect(result.first, 0.02);
    });

    test('process software waveform produces valid normalized heights', () {
      final dummyWaveform = List<int>.generate(256, (i) => (128 + (i % 50)));
      final result = FftProcessor.process(dummyWaveform, 60);

      expect(result.length, 60);
      for (final val in result) {
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThanOrEqualTo(1.0));
      }
    });
  });
}
