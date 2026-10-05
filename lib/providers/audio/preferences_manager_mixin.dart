import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin PreferencesManagerMixin on ChangeNotifier {
  bool _showInlineLyrics = true;
  bool get showInlineLyrics => _showInlineLyrics;

  bool _isCrossfadeEnabled = true;
  bool get isCrossfadeEnabled => _isCrossfadeEnabled;

  bool _showVisualizer = true;
  bool get showVisualizer => _showVisualizer;

  bool _smoothMediaPause = true;
  bool get smoothMediaPause => _smoothMediaPause;

  Future<void> initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isCrossfadeEnabled = prefs.getBool('enable_crossfade') ?? true;
    _showVisualizer = prefs.getBool('show_visualizer') ?? true;
    _showInlineLyrics = prefs.getBool('show_inline_lyrics') ?? true;
    _smoothMediaPause = prefs.getBool('smooth_media_pause') ?? true;
    notifyListeners();
  }

  Future<void> toggleCrossfade() async {
    _isCrossfadeEnabled = !_isCrossfadeEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_crossfade', _isCrossfadeEnabled);
    notifyListeners();
  }

  Future<void> toggleVisualizer() async {
    _showVisualizer = !_showVisualizer;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_visualizer', _showVisualizer);
    notifyListeners();
  }

  Future<void> toggleInlineLyrics() async {
    _showInlineLyrics = !_showInlineLyrics;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_inline_lyrics', _showInlineLyrics);
    notifyListeners();
  }

  Future<void> toggleSmoothMediaPause([bool? value]) async {
    _smoothMediaPause = value ?? !_smoothMediaPause;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smooth_media_pause', _smoothMediaPause);
    notifyListeners();
  }
}
