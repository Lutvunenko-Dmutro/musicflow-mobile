import 'dart:math';

class HardwareFftProcessor {
  static List<double> _prevHwHeights = [];

  /// Hardware mode: Android sends N FFT bytes packed as:
  /// [DC_re, Nyquist_re, re1, im1, re2, im2, ...re(N/2-1), im(N/2-1)]
  /// All bytes are signed (-128..127 encoded as 0..255 by EventChannel).
  static List<double> processHardwareFft(
    List<int> fftBytes,
    int numBands, {
    double amplitudeBoost = 1.0,
  }) {
    const double hwBoost         = 2.0;
    const double hwPowerCurve    = 1.4;
    const double hwMinFreq       = 40.0;
    const double hwMaxFreq       = 14000.0;
    const double hwSmoothSide    = 0.25;
    const double hwSmoothSelf    = 0.50;
    const double hwTemporalBlend = 0.72;

    final result = List<double>.filled(numBands, 0.02);
    if (fftBytes.length < 4) return result;

    final int n = fftBytes.length;
    final int halfBins = n ~/ 2;
    final magnitudes = List<double>.filled(halfBins, 0.0);

    int signed(int b) => b > 127 ? b - 256 : b;

    magnitudes[0] = signed(fftBytes[0]).abs() / 128.0;
    if (halfBins > 1) {
      magnitudes[halfBins - 1] = signed(fftBytes[1]).abs() / 128.0;
    }
    for (int k = 1; k < halfBins - 1; k++) {
      final int idx = 2 + (k - 1) * 2;
      if (idx + 1 >= n) break;
      final double re = signed(fftBytes[idx]) / 128.0;
      final double im = signed(fftBytes[idx + 1]) / 128.0;
      magnitudes[k] = sqrt(re * re + im * im);
    }

    const double sampleRate = 44100.0;
    final double binHz = sampleRate / n;

    for (int i = 0; i < numBands; i++) {
      final double freqLow  = i > 0           ? hwMinFreq * pow(hwMaxFreq / hwMinFreq, (i - 0.5) / numBands) : hwMinFreq * 0.8;
      final double freqHigh = i < numBands - 1 ? hwMinFreq * pow(hwMaxFreq / hwMinFreq, (i + 0.5) / numBands) : hwMaxFreq;

      final int binLow  = (freqLow  / binHz).floor().clamp(0, halfBins - 1);
      final int binHigh = (freqHigh / binHz).ceil().clamp(0,  halfBins - 1);

      double peak = 0.0;
      for (int k = binLow; k <= binHigh; k++) {
        if (magnitudes[k] > peak) peak = magnitudes[k];
      }

      final double boosted = (peak * amplitudeBoost * hwBoost).clamp(0.0, 1.0);
      result[i] = max(0.02, pow(boosted, hwPowerCurve).toDouble());
    }

    final smoothed = List<double>.from(result);
    for (int i = 1; i < numBands - 1; i++) {
      smoothed[i] = result[i - 1] * hwSmoothSide + result[i] * hwSmoothSelf + result[i + 1] * hwSmoothSide;
    }
    
    if (_prevHwHeights.length != numBands) {
      _prevHwHeights = List<double>.from(smoothed);
    } else {
      for (int i = 0; i < numBands; i++) {
        smoothed[i] = _prevHwHeights[i] * hwTemporalBlend + smoothed[i] * (1.0 - hwTemporalBlend);
      }
      _prevHwHeights = List<double>.from(smoothed);
    }
    return smoothed;
  }
}
