import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:music_flow_mobile/utils/fft_tuning.dart';
import 'package:music_flow_mobile/utils/hardware_fft_processor.dart';

class FftProcessor {
  static final double _ln10 = log(10);
  static FFT? _fft;
  static Float64List? _window;
  static const int fftSize = 4096;
  static final Float64List _rollingBuffer = Float64List(fftSize);
  static int _lastSize = 0;

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

  static List<double> process(List<int> waveform, int numBands, {double amplitudeBoost = 2.5}) {
    List<double> newHeights = List.filled(numBands, 0.05);
    int inputSize = waveform.length;
    if (inputSize < 2) return newHeights;

    if (inputSize <= fftSize) {
      for (int i = 0; i < fftSize - inputSize; i++) {
        _rollingBuffer[i] = _rollingBuffer[i + inputSize];
      }
      for (int i = 0; i < inputSize; i++) {
        _rollingBuffer[fftSize - inputSize + i] = (waveform[i] - 128) / 128.0;
      }
    } else {
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

    final input = Float64List(fftSize);
    for (int i = 0; i < fftSize; i++) {
      input[i] = _rollingBuffer[i] * _window![i];
    }

    final freqData = _fft!.realFft(input);
    List<double> magnitudes = List.filled(freqData.length, 0.0);

    for (int i = 0; i < freqData.length; i++) {
      final complex = freqData[i];
      final real = complex.x;
      final imag = complex.y;
      magnitudes[i] = (sqrt(real * real + imag * imag) * 2.0) / fftSize;
    }

    if (magnitudes.isEmpty) return newHeights;

    double sampleRate = 44100.0;
    double binResolution = sampleRate / fftSize;

    for (int i = 0; i < numBands; i++) {
      double targetFreq;
      if (numBands == 60) {
        targetFreq = FftTuning.barFrequencies[i];
      } else {
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
        double exactBin = targetFreq / binResolution;
        int left = exactBin.floor();
        int right = left + 1;
        if (left < 1) left = 1;
        if (right >= magnitudes.length) right = magnitudes.length - 1;

        double fraction = exactBin - left;
        peak = magnitudes[left] * (1.0 - fraction) + magnitudes[right] * fraction;
      } else {
        for (int j = startIdx; j <= endIdx; j++) {
          if (magnitudes[j] > peak) {
            peak = magnitudes[j];
          }
        }
      }

      double normalizedPosition = i / numBands;
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

      double db = boostedPeak > 0.000001
          ? 20 * log(boostedPeak) / _ln10
          : -100.0;

      double maxDb = FftTuning.maxDbOffset + (weight > 1.0 ? 20 * log(weight) / _ln10 : 0.0);
      double dynamicRange = maxDb - FftTuning.noiseFloor;

      double normalized = ((db - FftTuning.noiseFloor) / dynamicRange).clamp(0.0, 1.0);
      normalized = (normalized * amplitudeBoost).clamp(0.0, 1.0);

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

    List<double> smoothedHeights = List.from(newHeights);
    for (int i = 0; i < numBands; i++) {
      bool hasLeft = i > 0;
      bool hasRight = i < numBands - 1;

      if (hasLeft && hasRight) {
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
