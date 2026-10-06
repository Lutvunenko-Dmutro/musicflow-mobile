import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/providers/equalizer/equalizer_presets_data.dart';
import 'package:music_flow_mobile/providers/equalizer/equalizer_settings_storage.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class EqualizerProvider extends ChangeNotifier {
  final AndroidEqualizer equalizer1;
  final AndroidEqualizer equalizer2;

  AndroidEqualizerParameters? _params1;
  AndroidEqualizerParameters? _params2;
  AndroidEqualizerParameters? get parameters => _params1;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  double _bassBoost = 0.0;
  double get bassBoost => _bassBoost;

  double _virtualizer = 0.0;
  double get virtualizer => _virtualizer;

  List<double> _bandGains = List.filled(EqualizerSettingsStorage.totalBands, 0.0);
  List<double> get bandGains => _bandGains;

  int get bandCount => EqualizerSettingsStorage.totalBands;
  double get minDecibels => _params1?.minDecibels ?? -15.0;
  double get maxDecibels => _params1?.maxDecibels ?? 15.0;

  double getBandFrequency(int index) {
    if (index >= 0 && index < equalizerFrequencies.length) {
      return equalizerFrequencies[index];
    }
    return 1000.0;
  }

  EqualizerProvider({required this.equalizer1, required this.equalizer2}) {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    if (Platform.isAndroid) await _initParameters();
  }

  Future<void> _loadSettings() async {
    final s = await EqualizerSettingsStorage.loadSettings();
    _isEnabled = s.isEnabled;
    _bassBoost = s.bassBoost;
    _virtualizer = s.virtualizer;
    _bandGains = List.from(s.bandGains);
    notifyListeners();
  }

  Future<void> _initParameters() async {
    try {
      AppLogger.info('Ініціалізація 10-смугового еквалайзера...', 'EQ');
      _params1 = await equalizer1.parameters;
      _params2 = await equalizer2.parameters;
      await _applyAllSettingsToHardware();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Помилка ініціалізації еквалайзера: $e', e, null, 'EQ');
    }
  }

  Future<void> initIfNeeded() async {
    if (_params1 == null) await _initParameters();
  }

  Future<void> _applyAllSettingsToHardware() async {
    await _applyEnabled();
    await _applyGainsToHardware();
  }

  Future<void> toggleEqualizer() async {
    _isEnabled = !_isEnabled;
    await EqualizerSettingsStorage.saveEnabled(_isEnabled);
    await _applyEnabled();
    notifyListeners();
  }

  Future<void> _applyEnabled() async {
    try {
      await equalizer1.setEnabled(_isEnabled);
      await equalizer2.setEnabled(_isEnabled);
    } catch (e) {
      AppLogger.warning('Не вдалося застосувати стан еквалайзера: $e', 'EQ');
    }
  }

  Future<void> setBassBoost(double value) async {
    _bassBoost = value;
    await EqualizerSettingsStorage.saveBass(value);
    await _applyGainsToHardware();
    notifyListeners();
  }

  Future<void> setVirtualizer(double value) async {
    _virtualizer = value;
    await EqualizerSettingsStorage.saveVirtualizer(value);
    await _applyGainsToHardware();
    notifyListeners();
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= _bandGains.length) return;
    _bandGains[bandIndex] = gain;
    await EqualizerSettingsStorage.saveBandGain(bandIndex, gain);
    notifyListeners();
    await _applyGainsToHardware();
  }

  Future<void> _applyGainsToHardware() async {
    if (_params1 == null || _params2 == null) return;
    try {
      final hwBands = _params1!.bands;
      final minD = minDecibels;
      final maxD = maxDecibels;
      final bassAdd = _bassBoost * maxD * 0.45;
      final virtAdd = _virtualizer * maxD * 0.35;

      if (hwBands.length == 10) {
        for (int i = 0; i < 10; i++) {
          double g = _bandGains[i];
          if (i <= 1) g += bassAdd;
          if (i >= 8) g += virtAdd;
          final clamped = g.clamp(minD, maxD);
          await _params1!.bands[i].setGain(clamped);
          await _params2!.bands[i].setGain(clamped);
        }
      } else if (hwBands.length == 5) {
        final mapped = [
          (_bandGains[0] * 0.4 + _bandGains[1] * 0.6) + bassAdd,
          (_bandGains[2] * 0.5 + _bandGains[3] * 0.5) + bassAdd * 0.3,
          (_bandGains[4] * 0.5 + _bandGains[5] * 0.5),
          (_bandGains[6] * 0.5 + _bandGains[7] * 0.5) + virtAdd * 0.4,
          (_bandGains[8] * 0.5 + _bandGains[9] * 0.5) + virtAdd,
        ];
        for (int i = 0; i < 5; i++) {
          final clamped = mapped[i].clamp(minD, maxD);
          await _params1!.bands[i].setGain(clamped);
          await _params2!.bands[i].setGain(clamped);
        }
      }
    } catch (e) {
      AppLogger.warning('Помилка застосування частот до аудіочипу: $e', 'EQ');
    }
  }

  Future<void> applyPreset(String presetName) async {
    final presetGains = equalizerPresetsData[presetName];
    if (presetGains != null) {
      for (int i = 0; i < bandCount && i < presetGains.length; i++) {
        _bandGains[i] = presetGains[i];
        await EqualizerSettingsStorage.saveBandGain(i, presetGains[i]);
      }
      notifyListeners();
      await _applyGainsToHardware();
    }
  }

  Future<void> resetPreset() async {
    for (int i = 0; i < bandCount; i++) {
      _bandGains[i] = 0.0;
      await EqualizerSettingsStorage.saveBandGain(i, 0.0);
    }
    _bassBoost = 0.0;
    _virtualizer = 0.0;
    await EqualizerSettingsStorage.saveBass(0.0);
    await EqualizerSettingsStorage.saveVirtualizer(0.0);
    notifyListeners();
    await _applyGainsToHardware();
  }
}
