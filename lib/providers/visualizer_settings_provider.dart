import 'package:flutter/foundation.dart';

enum VisualizerStyle { bars, mirrored, circle, wave }

class VisualizerSettingsProvider extends ChangeNotifier {
  double _attack = 0.60;
  double _release = 0.40;
  double _gravity = -0.008; // Оптимальна гравітація для чіткого падіння
  double _bounce = 0.060;   // Високий відскок
  double _amplitudeBoost = 1.0;
  VisualizerStyle _style = VisualizerStyle.bars;

  double get attack => _attack;
  double get release => _release;
  double get gravity => _gravity;
  double get bounce => _bounce;
  double get amplitudeBoost => _amplitudeBoost;
  VisualizerStyle get style => _style;

  void setAttack(double value) {
    _attack = value;
    notifyListeners();
  }

  void setRelease(double value) {
    _release = value;
    notifyListeners();
  }

  void setGravity(double value) {
    _gravity = value;
    notifyListeners();
  }

  void setBounce(double value) {
    _bounce = value;
    notifyListeners();
  }

  void setAmplitudeBoost(double value) {
    _amplitudeBoost = value;
    notifyListeners();
  }

  void setStyle(VisualizerStyle value) {
    _style = value;
    notifyListeners();
  }

  void reset() {
    _attack = 0.60;
    _release = 0.40;
    _gravity = -0.008;
    _bounce = 0.060;
    _amplitudeBoost = 1.0;
    _style = VisualizerStyle.bars;
    notifyListeners();
  }
}
