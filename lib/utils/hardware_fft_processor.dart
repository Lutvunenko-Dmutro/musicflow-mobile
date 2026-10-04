import 'dart:math';
import 'package:music_flow_mobile/utils/fft_tuning.dart';

class HardwareFftProcessor {
  static List<double> _prevHwHeights = [];

  /// Reset history for clean transitions
  static void resetHistory() {
    _prevHwHeights.clear();
  }

  /// Hardware mode: Android sends N FFT bytes packed as:
  /// [DC_re, Nyquist_re, re1, im1, re2, im2, ...re(N/2-1), im(N/2-1)]
  /// All bytes are signed (-128..127 encoded as 0..255 by EventChannel).
  static List<double> processHardwareFft(
    List<int> fftBytes,
    int numBands, {
    double amplitudeBoost = 1.0,
  }) {
    final result = List<double>.filled(numBands, 0.02);
    if (fftBytes.length < 4) return result;

    final int n = fftBytes.length;
    final int halfBins = n ~/ 2;
    final magnitudes = List<double>.filled(halfBins, 0.0);

    int signed(int b) => b > 127 ? b - 256 : b;

    // IMPORTANT: DC component (bin 0) is deliberately ignored (set to 0.0)
    // to prevent DC bias / microphone floor from locking low bass bars into a static pillar.
    magnitudes[0] = 0.0;

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
      double targetFreq;
      double prevFreq;
      double nextFreq;

      if (numBands == 60) {
        targetFreq = FftTuning.barFrequencies[i];
        prevFreq = i > 0 ? FftTuning.barFrequencies[i - 1] : targetFreq * 0.8;
        nextFreq = i < 59 ? FftTuning.barFrequencies[i + 1] : targetFreq * 1.2;
      } else {
        const minF = 35.0;
        const maxF = 12000.0;
        targetFreq = minF * pow(maxF / minF, i / (numBands - 1));
        prevFreq = targetFreq * 0.85;
        nextFreq = targetFreq * 1.15;
      }

      final double exactStartBin = (prevFreq + targetFreq) / 2.0 / binHz;
      final double exactEndBin = (targetFreq + nextFreq) / 2.0 / binHz;
      final double exactBin = targetFreq / binHz;

      double peak = 0.0;
      if (exactEndBin - exactStartBin <= 1.0) {
        // Fractional interpolation for narrow bass bins (prevents identical adjacent bars)
        final int left = exactBin.floor().clamp(1, halfBins - 1);
        final int right = (left + 1).clamp(1, halfBins - 1);
        final double frac = (exactBin - left).clamp(0.0, 1.0);
        peak = magnitudes[left] * (1.0 - frac) + magnitudes[right] * frac;

        // Smooth taper for sub-bass under bin 1 frequency
        if (exactBin < 1.0) {
          peak *= (exactBin / 1.0).clamp(0.45, 1.0);
        }
      } else {
        final int bLow = exactStartBin.floor().clamp(1, halfBins - 1);
        final int bHigh = exactEndBin.ceil().clamp(1, halfBins - 1);
        for (int k = bLow; k <= bHigh; k++) {
          if (magnitudes[k] > peak) peak = magnitudes[k];
        }
      }

      // Frequency-dependent calibration:
      // Red bars (i < 12): weight 0.70..1.10 (prevents bass clipping to ceiling at high volume)
      // Orange/Yellow/Blue: weight 1.20..2.60 (maintains crisp active response for vocals/highs)
      final double normalizedPos = i / numBands;
      double weight;
      if (normalizedPos < 0.20) {
        final double t = normalizedPos / 0.20;
        weight = 0.75 + (1.10 - 0.75) * t;
      } else if (normalizedPos < 0.50) {
        final double t = (normalizedPos - 0.20) / 0.30;
        weight = 1.10 + (1.70 - 1.10) * t;
      } else if (normalizedPos < 0.80) {
        final double t = (normalizedPos - 0.50) / 0.30;
        weight = 1.70 + (2.20 - 1.70) * t;
      } else {
        final double t = (normalizedPos - 0.80) / 0.20;
        weight = 2.20 + (2.60 - 2.20) * t;
      }

      double boosted = peak * amplitudeBoost * weight;

      // Soft-knee compression: loud peaks gently compress rather than flattening into a solid pillar
      if (boosted > 0.80) {
        boosted = 0.80 + (boosted - 0.80) * 0.35;
      }
      boosted = boosted.clamp(0.0, 0.95);

      // Power curve for punchy bass and dynamic contrast
      final double punch = normalizedPos < 0.20 ? 1.25 : 1.35;
      result[i] = max(0.02, pow(boosted, punch).toDouble());
    }

    // Spatial smoothing: 70% self, 15% neighbors for clear bar separation
    final smoothed = List<double>.from(result);
    for (int i = 0; i < numBands; i++) {
      final double left = i > 0 ? result[i - 1] : result[i];
      final double right = i < numBands - 1 ? result[i + 1] : result[i];
      smoothed[i] = left * 0.15 + result[i] * 0.70 + right * 0.15;
    }

    // Temporal smoothing: faster decay for bass so kick drums punch and release naturally
    if (_prevHwHeights.length != numBands) {
      _prevHwHeights = List<double>.from(smoothed);
    } else {
      for (int i = 0; i < numBands; i++) {
        final bool isBass = i < 15;
        final bool isRising = smoothed[i] > _prevHwHeights[i];
        final double blend = isBass
            ? (isRising ? 0.40 : 0.52)
            : (isRising ? 0.50 : 0.68);

        smoothed[i] = _prevHwHeights[i] * blend + smoothed[i] * (1.0 - blend);
      }
      _prevHwHeights = List<double>.from(smoothed);
    }
    return smoothed;
  }
}
