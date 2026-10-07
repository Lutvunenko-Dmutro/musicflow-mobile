import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:music_flow_mobile/utils/fft_tuning.dart';
import 'package:music_flow_mobile/utils/hardware_fft_processor.dart';

class FftProcessor {
  static FFT? _fft;
  static Float64List? _window;
  static const int fftSize = 1024;
  static final Float64List _buffer = Float64List(fftSize);
  static List<double> _prevSwHeights = [];

  /// Reset history for clean transitions between tracks or play states
  static void resetHistory() {
    _prevSwHeights.clear();
    HardwareFftProcessor.resetHistory();
  }

  static List<double> processHardwareFft(
    List<int> fftBytes,
    int numBands, {
    double amplitudeBoost = 1.0,
  }) {
    return HardwareFftProcessor.processHardwareFft(
      fftBytes,
      numBands,
      amplitudeBoost: amplitudeBoost,
    );
  }

  /// Software FFT: real-time analysis of PCM waveform from audio stream
  static List<double> process(
    List<int> waveform,
    int numBands, {
    double amplitudeBoost = 1.0,
  }) {
    final List<double> result = List.filled(numBands, 0.02);
    final int inputSize = waveform.length;
    if (inputSize < 4) return result;

    if (_fft == null) {
      _fft = FFT(fftSize);
      _window = Float64List(fftSize);
      for (int i = 0; i < fftSize; i++) {
        _window![i] = 0.5 * (1 - cos(2 * pi * i / (fftSize - 1)));
      }
    }

    final int copyLen = min(inputSize, fftSize);
    for (int i = 0; i < copyLen; i++) {
      _buffer[i] = ((waveform[i] - 128) / 128.0) * _window![i];
    }
    for (int i = copyLen; i < fftSize; i++) {
      _buffer[i] = 0.0;
    }

    final freqData = _fft!.realFft(_buffer);
    final int halfBins = freqData.length;
    final List<double> magnitudes = List.filled(halfBins, 0.0);

    // Skip DC component (bin 0) to avoid sub-audible DC bias
    magnitudes[0] = 0.0;
    for (int i = 1; i < halfBins; i++) {
      final complex = freqData[i];
      final double re = complex.x;
      final double im = complex.y;
      magnitudes[i] = (sqrt(re * re + im * im) * 2.0) / fftSize;
    }

    const double sampleRate = 44100.0;
    final double binHz = sampleRate / fftSize; // ~43.066 Hz

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
        final int lo = pos.floor();
        final int hi = min(59, lo + 1);
        final double fr = pos - lo;
        targetFreq = FftTuning.barFrequencies[lo] * (1.0 - fr) +
            FftTuning.barFrequencies[hi] * fr;
        final double delta = hi > lo
            ? (FftTuning.barFrequencies[hi] - FftTuning.barFrequencies[lo])
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
        // Micro-detune for expanded bar counts to keep bass bars independent
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

      // Calibrated 5-band color curves matching UI blocks (12 bars each for 60 bars):
      // 0.0..0.20: 🟥 Red (Sub-bass / Kick, 30Hz - 180Hz)
      // 0.20..0.40: 🟧 Orange (Bass / Low Mids / Snare, 205Hz - 760Hz)
      // 0.40..0.60: 🟨 Yellow (Vocals / Guitars, 860Hz - 2310Hz)
      // 0.60..0.80: 🟦 Light Blue (Presence / High Mids, 2510Hz - 5500Hz)
      // 0.80..1.00: 🌌 Deep Blue (Highs / Air / Cymbals, 5800Hz - 10000Hz)
      final double normalizedPos = i / numBands;
      double weight;
      double punch;

      if (normalizedPos < 0.20) {
        final double t = normalizedPos / 0.20;
        weight = 2.40 + (3.20 - 2.40) * t;
        punch = 1.15;
      } else if (normalizedPos < 0.40) {
        final double t = (normalizedPos - 0.20) / 0.20;
        weight = 4.20 + (6.20 - 4.20) * t;
        punch = 1.22;
      } else if (normalizedPos < 0.60) {
        final double t = (normalizedPos - 0.40) / 0.20;
        weight = 6.80 + (10.50 - 6.80) * t;
        punch = 1.28;
      } else if (normalizedPos < 0.80) {
        final double t = (normalizedPos - 0.60) / 0.20;
        weight = 11.00 + (16.00 - 11.00) * t;
        punch = 1.32;
      } else {
        final double t = (normalizedPos - 0.80) / 0.20;
        weight = 16.50 + (23.00 - 16.50) * t;
        punch = 1.35;
      }

      double boosted = peak * amplitudeBoost * weight;

      // Soft-knee headroom protection: prevents clipping into a flat pillar
      if (boosted > 0.75) {
        boosted = 0.75 + (boosted - 0.75) * 0.35;
      }
      boosted = boosted.clamp(0.0, 0.95);

      result[i] = max(0.02, pow(boosted, punch).toDouble());
    }

    // Spatial smoothing: 70% self, 15% neighbors for distinct separation
    final smoothed = List<double>.from(result);
    for (int i = 0; i < numBands; i++) {
      final double left = i > 0 ? result[i - 1] : result[i];
      final double right = i < numBands - 1 ? result[i + 1] : result[i];
      smoothed[i] = left * 0.15 + result[i] * 0.70 + right * 0.15;
    }

    // Temporal smoothing: quick attack for punchy beats, smooth release
    if (_prevSwHeights.length != numBands) {
      _prevSwHeights = List<double>.from(smoothed);
    } else {
      for (int i = 0; i < numBands; i++) {
        final bool isBass = i < 15;
        final bool isRising = smoothed[i] > _prevSwHeights[i];
        final double blend = isBass
            ? (isRising ? 0.30 : 0.45)
            : (isRising ? 0.38 : 0.55);
        _prevSwHeights[i] =
            _prevSwHeights[i] * blend + smoothed[i] * (1.0 - blend);
      }
    }

    return List<double>.from(_prevSwHeights);
  }
}
