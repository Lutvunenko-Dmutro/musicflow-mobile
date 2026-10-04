import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:music_flow_mobile/utils/fft_tuning.dart';

class FftProcessor {
  static final double _ln10 = log(10);
  static FFT? _fft;
  static Float64List? _window;
  static const int fftSize = 4096;
  static final Float64List _rollingBuffer = Float64List(fftSize);
  static int _lastSize = 0;
  static List<double> _prevHwHeights = [];

  /// Hardware mode: Android sends N FFT bytes packed as:
  /// [DC_re, Nyquist_re, re1, im1, re2, im2, ...re(N/2-1), im(N/2-1)]
  /// All bytes are signed (-128..127 encoded as 0..255 by EventChannel).
  static List<double> processHardwareFft(List<int> fftBytes, int numBands, {double amplitudeBoost = 1.0}) {
    // ╔══════════════════════════════════════════╗
    // ║        HARDWARE FFT TUNING               ║
    // ╠══════════════════════════════════════════╣
    const double hwBoost         = 2.0;   // Множник підсилення (↑ вище = голосніше)
    const double hwPowerCurve    = 1.4;   // Крива стиснення (↑ вище = тихіше шумові піки)
    const double hwMinFreq       = 40.0;  // Нижня частота смуг (Гц)
    const double hwMaxFreq       = 14000.0; // Верхня частота смуг (Гц)
    const double hwSmoothSide    = 0.25;  // Вага сусідніх смуг при згладжуванні
    const double hwSmoothSelf    = 0.50;  // Вага поточної смуги при згладжуванні
    const double hwTemporalBlend = 0.72;  // Вага ПОПЕРЕДНЬОГО кадру (плавний плавний перехід без смикання)
    // ╚══════════════════════════════════════════╝

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
    // Temporal smoothing: blend with previous frame
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

  static List<double> process(List<int> waveform, int numBands, {double amplitudeBoost = 2.5}) {
    List<double> newHeights = List.filled(numBands, 0.05);
    int inputSize = waveform.length;
    if (inputSize < 2) return newHeights;

    // 1. Shift the rolling buffer to the left
    if (inputSize <= fftSize) {
      for (int i = 0; i < fftSize - inputSize; i++) {
        _rollingBuffer[i] = _rollingBuffer[i + inputSize];
      }
      // 2. Append new waveform
      for (int i = 0; i < inputSize; i++) {
        _rollingBuffer[fftSize - inputSize + i] = (waveform[i] - 128) / 128.0;
      }
    } else {
      // If waveform is somehow larger than buffer, just take the end
      for (int i = 0; i < fftSize; i++) {
        _rollingBuffer[i] = (waveform[inputSize - fftSize + i] - 128) / 128.0;
      }
    }

    if (_lastSize != fftSize || _fft == null) {
      _fft = FFT(fftSize);
      _window = Float64List(fftSize);
      for (int i = 0; i < fftSize; i++) {
        _window![i] = 0.5 * (1 - cos(2 * pi * i / (fftSize - 1)));
      }
      _lastSize = fftSize;
    }

    // 3. Apply window to rolling buffer
    final input = Float64List(fftSize);
    for (int i = 0; i < fftSize; i++) {
      input[i] = _rollingBuffer[i] * _window![i];
    }

    // Compute FFT using fftea
    final freqData = _fft!.realFft(input);

    List<double> magnitudes = List.filled(freqData.length, 0.0);

    // Calculate magnitudes
    for (int i = 0; i < freqData.length; i++) {
      final complex = freqData[i];
      final real = complex.x;
      final imag = complex.y;
      magnitudes[i] = (sqrt(real * real + imag * imag) * 2.0) / fftSize;
    }

    if (magnitudes.isEmpty) return newHeights;

    double sampleRate = 44100.0; // Typical Android audio capture rate
    double binResolution = sampleRate / fftSize; // e.g., 10.7 Hz per bin!

    for (int i = 0; i < numBands; i++) {
      // Use our explicit frequency array (fallback to a formula if numBands != 60)
      double targetFreq;
      if (numBands == 60) {
        targetFreq = FftTuning.barFrequencies[i];
      } else {
        // Fallback logarithmic calculation
        double minFreq = 40.0;
        double maxFreq = 10000.0;
        targetFreq = minFreq * pow(maxFreq / minFreq, i / numBands);
      }

      double prevFreq = i > 0 && numBands == 60
          ? FftTuning.barFrequencies[i - 1]
          : targetFreq * 0.8;
      double nextFreq = i < numBands - 1 && numBands == 60
          ? FftTuning.barFrequencies[i + 1]
          : targetFreq * 1.2;

      double exactStartBin = (prevFreq + targetFreq) / 2.0 / binResolution;
      double exactEndBin = (targetFreq + nextFreq) / 2.0 / binResolution;

      int startIdx = exactStartBin.floor();
      int endIdx = exactEndBin.floor();

      if (startIdx < 1) startIdx = 1;
      if (endIdx >= magnitudes.length) endIdx = magnitudes.length - 1;
      if (startIdx > endIdx) startIdx = endIdx;

      double peak = 0.0;
      if (startIdx == endIdx) {
        // Interpolate for sub-bin frequencies (e.g., bass frequencies smaller than bin resolution)
        double exactBin = targetFreq / binResolution;
        int left = exactBin.floor();
        int right = left + 1;
        if (left < 1) left = 1;
        if (right >= magnitudes.length) right = magnitudes.length - 1;

        double fraction = exactBin - left;
        peak = magnitudes[left] * (1.0 - fraction) + magnitudes[right] * fraction;
      } else {
        // Find max peak in the bin range
        for (int j = startIdx; j <= endIdx; j++) {
          if (magnitudes[j] > peak) {
            peak = magnitudes[j];
          }
        }
      }

      double normalizedPosition = i / numBands;

      // Плавна інтерполяція ваги (щоб не було різких сходинок між кольорами)
      double weight;
      if (normalizedPosition < 0.40) {
        double t = normalizedPosition / 0.40;
        weight = FftTuning.weightRed + (FftTuning.weightOrange - FftTuning.weightRed) * t;
      } else if (normalizedPosition < 0.70) {
        double t = (normalizedPosition - 0.40) / 0.30;
        weight = FftTuning.weightOrange + (FftTuning.weightYellow - FftTuning.weightOrange) * t;
      } else if (normalizedPosition < 0.90) {
        double t = (normalizedPosition - 0.70) / 0.20;
        weight = FftTuning.weightYellow + (FftTuning.weightBlue - FftTuning.weightYellow) * t;
      } else {
        double t = (normalizedPosition - 0.90) / 0.10;
        weight = FftTuning.weightBlue + (FftTuning.weightBlue * 1.2 - FftTuning.weightBlue) * t; 
      }
      
      double boostedPeak = peak * weight;

      // Calculate Decibels (values will be negative, e.g. -60dB to 0dB)
      double db = boostedPeak > 0.000001
          ? 20 * log(boostedPeak) / _ln10
          : -100.0;

      // Dynamic range tuned for normalized fftea output
      double maxDb = FftTuning.maxDbOffset + (weight > 1.0 ? 20 * log(weight) / _ln10 : 0.0);
      double dynamicRange = maxDb - FftTuning.noiseFloor;

      double normalized = ((db - FftTuning.noiseFloor) / dynamicRange).clamp(0.0, 1.0);
      
      // БУСТ АМПЛІТУДИ: множимо результат, щоб смужки стрибали значно вище
      normalized = (normalized * amplitudeBoost).clamp(0.0, 1.0);

      // Плавна інтерполяція різкості
      double punchPower;
      if (normalizedPosition < 0.40) {
        double t = normalizedPosition / 0.40;
        punchPower = FftTuning.punchRed + (FftTuning.punchOrange - FftTuning.punchRed) * t;
      } else if (normalizedPosition < 0.70) {
        double t = (normalizedPosition - 0.40) / 0.30;
        punchPower = FftTuning.punchOrange + (FftTuning.punchYellow - FftTuning.punchOrange) * t;
      } else if (normalizedPosition < 0.90) {
        double t = (normalizedPosition - 0.70) / 0.20;
        punchPower = FftTuning.punchYellow + (FftTuning.punchBlue - FftTuning.punchYellow) * t;
      } else {
        punchPower = FftTuning.punchBlue;
      }
      
      double punchy = pow(normalized, punchPower).toDouble();
      newHeights[i] = max(0.02, punchy);
    }

    // --- SPATIAL SMOOTHING (Beautiful Continuous Waves) ---
    List<double> smoothedHeights = List.from(newHeights);
    for (int i = 0; i < numBands; i++) {
      bool hasLeft = i > 0;
      bool hasRight = i < numBands - 1;

      if (hasLeft && hasRight) {
        // Плавна хвиля по всьому графіку (без розривів між кольорами)
        smoothedHeights[i] = newHeights[i - 1] * FftTuning.smoothNeighbor + newHeights[i] * FftTuning.smoothSelf + newHeights[i + 1] * FftTuning.smoothNeighbor;
      } else if (hasLeft) {
        smoothedHeights[i] = newHeights[i] * (1.0 - FftTuning.smoothNeighbor) + newHeights[i - 1] * FftTuning.smoothNeighbor;
      } else if (hasRight) {
        smoothedHeights[i] = newHeights[i] * (1.0 - FftTuning.smoothNeighbor) + newHeights[i + 1] * FftTuning.smoothNeighbor;
      } else {
        smoothedHeights[i] = newHeights[i];
      }
    }

    return smoothedHeights;
  }
}
