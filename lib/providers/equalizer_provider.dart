import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/equalizer_presets_data.dart';

class EqualizerProvider extends ChangeNotifier {
  final AndroidEqualizer equalizer1;
  final AndroidEqualizer equalizer2;

  AndroidEqualizerParameters? _params1;
  AndroidEqualizerParameters? _params2;
  
  AndroidEqualizerParameters? get parameters => _params1; // Use params1 for UI
  
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;
  
  double _bassBoost = 0.0;
  double get bassBoost => _bassBoost;

  List<double> _bandGains = List.filled(5, 0.0);
  List<double> get bandGains {
    if (_bandGains.isEmpty) {
      _bandGains = List.filled(bandCount, 0.0);
    }
    return _bandGains;
  }

  int get bandCount => _params1 != null ? _params1!.bands.length : 5;
  double get minDecibels => _params1 != null ? _params1!.minDecibels : -15.0;
  double get maxDecibels => _params1 != null ? _params1!.maxDecibels : 15.0;

  double getBandFrequency(int index) {
    if (_params1 != null) {
      return _params1!.bands[index].centerFrequency;
    }
    const mockFreqs = [60.0, 230.0, 910.0, 3600.0, 14000.0];
    return index < mockFreqs.length ? mockFreqs[index] : 0.0;
  }

  EqualizerProvider({
    required this.equalizer1,
    required this.equalizer2,
  }) {
    // Initialize mock gains from prefs early so UI works immediately
    _bandGains = List.filled(5, 0.0);
    _loadSettingsEarly();
    if (Platform.isAndroid) {
      _initParameters();
    }
  }

  double _virtualizer = 0.0;
  double get virtualizer => _virtualizer;

  Future<void> _loadSettingsEarly() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('eq_enabled') ?? false;
    _bassBoost = prefs.getDouble('eq_bass') ?? 0.0;
    _virtualizer = prefs.getDouble('eq_virt') ?? 0.0;
    for (int i = 0; i < 5; i++) {
      _bandGains[i] = prefs.getDouble('eq_band_$i') ?? 0.0;
    }
    notifyListeners();
  }

  Future<void> _initParameters() async {
    try {
      debugPrint('🎵 [EQ] Initializing equalizer parameters...');
      _params1 = await equalizer1.parameters;
      _params2 = await equalizer2.parameters;
      if (_params1 != null) {
        debugPrint('🎵 [EQ] Parameters received. Bands count: ${_params1!.bands.length}');
        // Adjust array size if real device has more/less bands
        final actualLength = _params1!.bands.length;
        if (_bandGains.length != actualLength) {
          final oldGains = List<double>.from(_bandGains);
          _bandGains = List.filled(actualLength, 0.0);
          for (int i = 0; i < actualLength && i < oldGains.length; i++) {
            _bandGains[i] = oldGains[i];
          }
        }
      } else {
        debugPrint('⚠️ [EQ] Parameters are null from just_audio!');
      }
      await _loadSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [EQ] Equalizer init failed: $e');
    }
  }

  Future<void> initIfNeeded() async {
    if (_params1 == null) {
      await _initParameters();
    }
  }

  Future<void> _loadSettings() async {
    debugPrint('🎵 [EQ] Loading settings...');
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('eq_enabled') ?? false;
    _bassBoost = prefs.getDouble('eq_bass') ?? 0.0;
    _virtualizer = prefs.getDouble('eq_virt') ?? 0.0;
    
    await _applyEnabled();
    await _applyBassBoost();
    await _applyVirtualizer();

    if (_params1 != null && _params2 != null) {
      for (int i = 0; i < _params1!.bands.length; i++) {
        final gain = prefs.getDouble('eq_band_$i') ?? 0.0;
        _bandGains[i] = gain;
        _params1!.bands[i].setGain(gain);
        _params2!.bands[i].setGain(gain);
        debugPrint('🎵 [EQ] Loaded band $i gain: $gain dB');
      }
    }
  }

  Future<void> toggleEqualizer() async {
    _isEnabled = !_isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eq_enabled', _isEnabled);
    await _applyEnabled();
    notifyListeners();
  }
  
  Future<void> _applyEnabled() async {
    try {
      debugPrint('🎵 [EQ] Applying enabled state: $_isEnabled, virtualizer: $_virtualizer');
      await equalizer1.setEnabled(_isEnabled);
      await equalizer2.setEnabled(_isEnabled);
      debugPrint('🎵 [EQ] Successfully applied enabled state');
    } catch (e) {
      debugPrint('❌ [EQ] Could not apply enabled: $e');
    }
  }

  Future<void> setBassBoost(double value) async {
    debugPrint('🎵 [EQ] setBassBoost called: $value');
    _bassBoost = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eq_bass', value);
    await _applyBassBoost();
    notifyListeners();
  }

  Future<void> _applyBassBoost() async {
    if (_params1 == null || _params2 == null) {
      debugPrint('⚠️ [EQ] _applyBassBoost skipped because params are null');
      return;
    }
    try {
      final maxD = _params1!.maxDecibels;
      final minD = _params1!.minDecibels;
      final bassGain = _bassBoost * maxD * 0.5; 
      final virtGain = _virtualizer * maxD * 0.4;
      
      debugPrint('🎵 [EQ] Applying software effects -> bassGain: $bassGain, virtGain: $virtGain');

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
      debugPrint('❌ [EQ] Could not apply software effects: $e');
    }
  }

  Future<void> setVirtualizer(double value) async {
    debugPrint('🎵 [EQ] setVirtualizer called: $value');
    _virtualizer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eq_virt', value);
    await _applyVirtualizer();
    await _applyEnabled(); // Re-evaluate enabled state
    notifyListeners();
  }

  Future<void> _applyVirtualizer() async {
    await _applyBassBoost(); // Virtualizer now runs through software EQ
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    _bandGains[bandIndex] = gain;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eq_band_$bandIndex', gain);
    notifyListeners();

    if (_params1 == null || _params2 == null) return;
    try {
      await _params1!.bands[bandIndex].setGain(gain);
      await _params2!.bands[bandIndex].setGain(gain);
    } catch (e) {
      debugPrint('Could not apply band gain: $e');
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
