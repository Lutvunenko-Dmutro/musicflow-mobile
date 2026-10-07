import 'dart:math';
import 'package:music_flow_mobile/utils/fft_tuning.dart';

// 🔒 CALIBRATED & LOCKED: Цей алгоритм і коефіцієнти відкалібровані та ідеально протестовані на пристрої.
// НЕ ЗМІНЮВАТИ без прямого запиту користувача!
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
        final double pos = (i / (numBands - 1)) * 59.0;
        final int low = pos.floor();
        final int high = min(59, low + 1);
        final double frac = pos - low;
        targetFreq = FftTuning.barFrequencies[low] * (1.0 - frac) +
            FftTuning.barFrequencies[high] * frac;
        final double delta = high > low
            ? (FftTuning.barFrequencies[high] - FftTuning.barFrequencies[low])
            : targetFreq * 0.12;
        prevFreq = targetFreq - delta * 0.5;
        nextFreq = targetFreq + delta * 0.5;
      }

      final double exactStartBin = (prevFreq + targetFreq) / 2.0 / binHz;
      final double exactEndBin = (targetFreq + nextFreq) / 2.0 / binHz;
      final double exactBin = targetFreq / binHz;

      double peak = 0.0;
      if (exactEndBin - exactStartBin <= 1.0) {
        final int left = exactBin.floor().clamp(1, halfBins - 1);
        final int right = (left + 1).clamp(1, halfBins - 1);
        final double frac = (exactBin - left).clamp(0.0, 1.0);
        peak = magnitudes[left] * (1.0 - frac) + magnitudes[right] * frac;

        if (exactBin < 1.0) {
          peak *= (exactBin / 1.0).clamp(0.45, 1.0);
        }
        if (numBands != 60 && (i / numBands) < 0.40) {
          final double detune = sin((i * 1.618) + (peak * 3.14)) * 0.12;
          peak = (peak * (1.0 + detune)).clamp(0.02, 1.0);
        }
      } else {
        final int bLow = exactStartBin.floor().clamp(1, halfBins - 1);
        final int bHigh = exactEndBin.ceil().clamp(1, halfBins - 1);
        for (int k = bLow; k <= bHigh; k++) {
          if (magnitudes[k] > peak) peak = magnitudes[k];
        }
      }

      final double normalizedPos = i / numBands;
      double weight;
      if (normalizedPos < 0.40) {
        final double t = normalizedPos / 0.40;
        weight = 0.75 + (1.10 - 0.75) * t;
      } else if (normalizedPos < 0.65) {
        final double t = (normalizedPos - 0.40) / 0.25;
        weight = 1.10 + (1.70 - 1.10) * t;
      } else if (normalizedPos < 0.85) {
        final double t = (normalizedPos - 0.65) / 0.20;
        weight = 1.70 + (2.20 - 1.70) * t;
      } else {
        final double t = (normalizedPos - 0.85) / 0.15;
        weight = 2.20 + (2.60 - 2.20) * t;
      }

      double boosted = peak * amplitudeBoost * weight;

      if (boosted > 0.80) {
        boosted = 0.80 + (boosted - 0.80) * 0.35;
      }
      boosted = boosted.clamp(0.0, 0.95);

      final double punch = normalizedPos < 0.40 ? 1.25 : 1.35;
      result[i] = max(0.02, pow(boosted, punch).toDouble());
    }

    final smoothed = List<double>.from(result);
    for (int i = 0; i < numBands; i++) {
      final double left = i > 0 ? result[i - 1] : result[i];
      final double right = i < numBands - 1 ? result[i + 1] : result[i];
      smoothed[i] = left * 0.15 + result[i] * 0.70 + right * 0.15;
    }

    if (_prevHwHeights.length != numBands) {
      _prevHwHeights = List<double>.from(smoothed);
    } else {
      for (int i = 0; i < numBands; i++) {
        final bool isBass = (i / numBands) < 0.40;
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
