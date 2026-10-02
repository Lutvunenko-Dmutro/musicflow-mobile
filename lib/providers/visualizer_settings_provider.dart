import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/native_visualizer_service.dart';

enum VisualizerStyle { bars, mirrored, circle, wave }
enum VisualizerCore { software, hardware }

/// Settings for one specific core (Software or Hardware).
class CoreSettings {
  double attack;
  double release;
  double gravity;
  double bounce;
  double amplitudeBoost;

  CoreSettings({
    required this.attack,
    required this.release,
    required this.gravity,
    required this.bounce,
    required this.amplitudeBoost,
  });

  static CoreSettings softwareDefaults() => CoreSettings(
    attack: 0.60, release: 0.40, gravity: -0.008, bounce: 0.060, amplitudeBoost: 1.0,
  );

  static CoreSettings hardwareDefaults() => CoreSettings(
    attack: 0.30, release: 0.20, gravity: -0.005, bounce: 0.030, amplitudeBoost: 1.0,
  );

  Map<String, double> toMap() => {
    'attack': attack, 'release': release, 'gravity': gravity,
    'bounce': bounce, 'amplitudeBoost': amplitudeBoost,
  };

  void loadFrom(Map<String, double?> map) {
    attack         = map['attack']         ?? attack;
    release        = map['release']        ?? release;
    gravity        = map['gravity']        ?? gravity;
    bounce         = map['bounce']         ?? bounce;
    amplitudeBoost = map['amplitudeBoost'] ?? amplitudeBoost;
  }
}

class VisualizerSettingsProvider extends ChangeNotifier {
  final CoreSettings _sw = CoreSettings.softwareDefaults();
  final CoreSettings _hw = CoreSettings.hardwareDefaults();

  VisualizerStyle _style = VisualizerStyle.bars;
  VisualizerCore  _core  = VisualizerCore.software;

  VisualizerSettingsProvider() { _loadSettings(); }

  CoreSettings get _current => _core == VisualizerCore.hardware ? _hw : _sw;

  // ── Getters (always return values for the ACTIVE core) ─────────────────
  double         get attack         => _current.attack;
  double         get release        => _current.release;
  double         get gravity        => _current.gravity;
  double         get bounce         => _current.bounce;
  double         get amplitudeBoost => _current.amplitudeBoost;
  VisualizerStyle get style          => _style;
  VisualizerCore  get core           => _core;

  // ── Setters (write into the ACTIVE core's settings) ────────────────────
  void setAttack(double v)         { _current.attack = v;          _save(); notifyListeners(); }
  void setRelease(double v)        { _current.release = v;         _save(); notifyListeners(); }
  void setGravity(double v)        { _current.gravity = v;         _save(); notifyListeners(); }
  void setBounce(double v)         { _current.bounce = v;          _save(); notifyListeners(); }
  void setAmplitudeBoost(double v) { _current.amplitudeBoost = v;  _save(); notifyListeners(); }
  void setStyle(VisualizerStyle v) { _style = v;                    _save(); notifyListeners(); }

  Future<void> setCore(VisualizerCore value) async {
    _core = value;
    NativeVisualizerService.setVisualizerCore(value.name);
    await _save();
    notifyListeners();
  }

  void reset() {
    if (_core == VisualizerCore.hardware) {
      final d = CoreSettings.hardwareDefaults();
      _hw.attack = d.attack; _hw.release = d.release; _hw.gravity = d.gravity;
      _hw.bounce = d.bounce; _hw.amplitudeBoost = d.amplitudeBoost;
    } else {
      final d = CoreSettings.softwareDefaults();
      _sw.attack = d.attack; _sw.release = d.release; _sw.gravity = d.gravity;
      _sw.bounce = d.bounce; _sw.amplitudeBoost = d.amplitudeBoost;
    }
    _save();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _core = VisualizerCore.values[prefs.getInt('visualizer_core') ?? 0];
    _style = VisualizerStyle.values[prefs.getInt('visualizer_style') ?? 0];

    _sw.loadFrom({
      'attack':         prefs.getDouble('sw_attack'),
      'release':        prefs.getDouble('sw_release'),
      'gravity':        prefs.getDouble('sw_gravity'),
      'bounce':         prefs.getDouble('sw_bounce'),
      'amplitudeBoost': prefs.getDouble('sw_amplitudeBoost'),
    });
    _hw.loadFrom({
      'attack':         prefs.getDouble('hw_attack'),
      'release':        prefs.getDouble('hw_release'),
      'gravity':        prefs.getDouble('hw_gravity'),
      'bounce':         prefs.getDouble('hw_bounce'),
      'amplitudeBoost': prefs.getDouble('hw_amplitudeBoost'),
    });

    NativeVisualizerService.setVisualizerCore(_core.name);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('visualizer_core',  _core.index);
    await prefs.setInt('visualizer_style', _style.index);
    final prefix = _core == VisualizerCore.hardware ? 'hw' : 'sw';
    await prefs.setDouble('${prefix}_attack',         _current.attack);
    await prefs.setDouble('${prefix}_release',        _current.release);
    await prefs.setDouble('${prefix}_gravity',        _current.gravity);
    await prefs.setDouble('${prefix}_bounce',         _current.bounce);
    await prefs.setDouble('${prefix}_amplitudeBoost', _current.amplitudeBoost);
  }
}
