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

  List<double> _bandGains = List.filled(5, 0.0);
  List<double> get bandGains => _bandGains;

  int get bandCount => _params1?.bands.length ?? 5;
  double get minDecibels => _params1?.minDecibels ?? -15.0;
  double get maxDecibels => _params1?.maxDecibels ?? 15.0;

  double getBandFrequency(int index) {
    if (_params1 != null) return _params1!.bands[index].centerFrequency;
    const mockFreqs = [60.0, 230.0, 910.0, 3600.0, 14000.0];
    return index < mockFreqs.length ? mockFreqs[index] : 0.0;
  }

  EqualizerProvider({required this.equalizer1, required this.equalizer2}) {
    _init();
  }

  double _virtualizer = 0.0;
  double get virtualizer => _virtualizer;

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
      AppLogger.info('Initializing equalizer parameters...', 'EQ');
      _params1 = await equalizer1.parameters;
      _params2 = await equalizer2.parameters;
      if (_params1 != null) {
        final actualLength = _params1!.bands.length;
        if (_bandGains.length != actualLength) {
          final oldGains = List<double>.from(_bandGains);
          _bandGains = List.filled(actualLength, 0.0);
          for (int i = 0; i < actualLength && i < oldGains.length; i++) {
            _bandGains[i] = oldGains[i];
          }
        }
      }
      await _applyAllSettingsToHardware();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Equalizer init failed: $e', e, null, 'EQ');
    }
  }

  Future<void> initIfNeeded() async {
    if (_params1 == null) await _initParameters();
  }

  Future<void> _applyAllSettingsToHardware() async {
    await _applyEnabled();
    await _applyBassBoost();
    await _applyVirtualizer();

    if (_params1 != null && _params2 != null) {
      for (int i = 0; i < _params1!.bands.length; i++) {
        final gain = i < _bandGains.length ? _bandGains[i] : 0.0;
        await _params1!.bands[i].setGain(gain);
        await _params2!.bands[i].setGain(gain);
      }
    }
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
      AppLogger.warning('Could not apply enabled state: $e', 'EQ');
    }
  }

  Future<void> setBassBoost(double value) async {
    _bassBoost = value;
    await EqualizerSettingsStorage.saveBass(value);
    await _applyBassBoost();
    notifyListeners();
  }

  Future<void> _applyBassBoost() async {
    if (_params1 == null || _params2 == null) return;
    try {
      final maxD = _params1!.maxDecibels;
      final minD = _params1!.minDecibels;
      final bassGain = _bassBoost * maxD * 0.5; 
      final virtGain = _virtualizer * maxD * 0.4;

      for (int i = 0; i < _params1!.bands.length; i++) {
        double currentGain = _bandGains[i];
        if (i == 0) currentGain += bassGain;
        if (i == 1) currentGain += bassGain * 0.5;
        if (i == 3) currentGain += virtGain * 0.5;
        if (i == 4) currentGain += virtGain;
        final finalGain = currentGain.clamp(minD, maxD);
        await _params1!.bands[i].setGain(finalGain);
        await _params2!.bands[i].setGain(finalGain);
      }
    } catch (e) {
      AppLogger.warning('Could not apply software effects: $e', 'EQ');
    }
  }

  Future<void> setVirtualizer(double value) async {
    _virtualizer = value;
    await EqualizerSettingsStorage.saveVirtualizer(value);
    await _applyVirtualizer();
    await _applyEnabled();
    notifyListeners();
  }

  Future<void> _applyVirtualizer() => _applyBassBoost();

  Future<void> setBandGain(int bandIndex, double gain) async {
    _bandGains[bandIndex] = gain;
    await EqualizerSettingsStorage.saveBandGain(bandIndex, gain);
    notifyListeners();

    if (_params1 == null || _params2 == null) return;
    try {
      await _params1!.bands[bandIndex].setGain(gain);
      await _params2!.bands[bandIndex].setGain(gain);
    } catch (e) {
      AppLogger.warning('Could not apply band gain: $e', 'EQ');
    }
  }
  
  Future<void> applyPreset(String presetName) async {
    final presetGains = equalizerPresetsData[presetName];
    if (presetGains != null) {
      for (int i = 0; i < bandCount && i < presetGains.length; i++) {
        await setBandGain(i, presetGains[i]);
      }
    }
  }

  Future<void> resetPreset() async {
    await applyPreset('Налаштувати');
    await setBassBoost(0.0);
    await setVirtualizer(0.0);
  }
}
