import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

class FftProcessor {
  static final double _ln10 = log(10);
  static FFT? _fft;
  static Float64List? _window;
  static const int fftSize = 4096;
  static final Float64List _rollingBuffer = Float64List(fftSize);
  static int _lastSize = 0;

  // ==========================================
  // 🎛️ НАЛАШТУВАННЯ ВІЗУАЛІЗАТОРА (ТЮНІНГ)
  // ==========================================
  
  // 1. Динамічний діапазон (чутливість до гучності)
  static const double noiseFloor = -45.0; // Трохи вищий поріг тиші, щоб відсікти шуми
  static const double maxDbOffset = -10.0; // Даємо більше місця для піків
  
  // 2. Чутливість гучності для КОЖНОГО кольору (Множники)
  static const double weightRed = 1.0;    // 🟥 Червоні (Бас)
  static const double weightOrange = 3.0; // 🟧 Оранжеві (Нижня середина)
  static const double weightYellow = 6.0; // 🟨 Жовті (Піаніно, вокал)
  static const double weightBlue = 8.0;   // 🟦 Сині (Тарілочки)
  
  // 3. Різкість (Punch) для КОЖНОГО кольору (чим вище, тим різкіше падає смужка)
  static const double punchRed = 1.5;
  static const double punchOrange = 1.5;
  static const double punchYellow = 1.5;
  static const double punchBlue = 1.5;

  // 4. Згладжування (Spatial Smoothing)
  static const double smoothSelf = 0.5;     // 50% від себе
  static const double smoothNeighbor = 0.25; // 25% від сусідів (більше хвилеподібності)
  
  // ==========================================

  static const List<double> barFrequencies = [
    // 🟥 Red (24 bars) - 30Hz to 800Hz (Захоплює Бочку, Бас-гітару, Томи і Робочий барабан!)
    30, 40, 50, 60, 70, 80, 95, 110, 125, 140, 160, 180, 205, 230, 260, 290, 325, 365, 410, 460, 520, 590, 670, 760,
    // 🟧 Orange (18 bars) - 860Hz to 3900Hz (Вокал, Гітари, Синтезатори)
    860, 960, 1070, 1190, 1320, 1460, 1610, 1770, 1940, 2120, 2310, 2510, 2720, 2940, 3170, 3410, 3660, 3920,
    // 🟨 Жовті (12 bars) - 4200Hz to 7300Hz (Скрипки, Тарілочки)
    4200, 4400, 4650, 4900, 5200, 5500, 5800, 6100, 6400, 6700, 7000, 7300,
    // 🟦 Сині (6 bars) - 7600Hz to 10000Hz (Свист, Хай-хети)
    7600, 8000, 8400, 8800, 9400, 10000,
  ];

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
        targetFreq = barFrequencies[i];
      } else {
        // Fallback logarithmic calculation
        double minFreq = 40.0;
        double maxFreq = 10000.0;
        targetFreq = minFreq * pow(maxFreq / minFreq, i / numBands);
      }

      double prevFreq = i > 0 && numBands == 60
          ? barFrequencies[i - 1]
          : targetFreq * 0.8;
      double nextFreq = i < numBands - 1 && numBands == 60
          ? barFrequencies[i + 1]
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
        weight = weightRed + (weightOrange - weightRed) * t;
      } else if (normalizedPosition < 0.70) {
        double t = (normalizedPosition - 0.40) / 0.30;
        weight = weightOrange + (weightYellow - weightOrange) * t;
      } else if (normalizedPosition < 0.90) {
        double t = (normalizedPosition - 0.70) / 0.20;
        weight = weightYellow + (weightBlue - weightYellow) * t;
      } else {
        double t = (normalizedPosition - 0.90) / 0.10;
        weight = weightBlue + (weightBlue * 1.2 - weightBlue) * t; 
      }
      
      double boostedPeak = peak * weight;

      // Calculate Decibels (values will be negative, e.g. -60dB to 0dB)
      double db = boostedPeak > 0.000001
          ? 20 * log(boostedPeak) / _ln10
          : -100.0;

      // Dynamic range tuned for normalized fftea output
      double maxDb = maxDbOffset + (weight > 1.0 ? 20 * log(weight) / _ln10 : 0.0);
      double dynamicRange = maxDb - noiseFloor;

      double normalized = ((db - noiseFloor) / dynamicRange).clamp(0.0, 1.0);
      
      // БУСТ АМПЛІТУДИ: множимо результат, щоб смужки стрибали значно вище
      normalized = (normalized * amplitudeBoost).clamp(0.0, 1.0);

      // Плавна інтерполяція різкості
      double punchPower;
      if (normalizedPosition < 0.40) {
        double t = normalizedPosition / 0.40;
        punchPower = punchRed + (punchOrange - punchRed) * t;
      } else if (normalizedPosition < 0.70) {
        double t = (normalizedPosition - 0.40) / 0.30;
        punchPower = punchOrange + (punchYellow - punchOrange) * t;
      } else if (normalizedPosition < 0.90) {
        double t = (normalizedPosition - 0.70) / 0.20;
        punchPower = punchYellow + (punchBlue - punchYellow) * t;
      } else {
        punchPower = punchBlue;
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
        smoothedHeights[i] = newHeights[i - 1] * smoothNeighbor + newHeights[i] * smoothSelf + newHeights[i + 1] * smoothNeighbor;
      } else if (hasLeft) {
        smoothedHeights[i] = newHeights[i] * (1.0 - smoothNeighbor) + newHeights[i - 1] * smoothNeighbor;
      } else if (hasRight) {
        smoothedHeights[i] = newHeights[i] * (1.0 - smoothNeighbor) + newHeights[i + 1] * smoothNeighbor;
      } else {
        smoothedHeights[i] = newHeights[i];
      }
    }

    return smoothedHeights;
  }
}
