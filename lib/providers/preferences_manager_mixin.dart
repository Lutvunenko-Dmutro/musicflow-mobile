import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin PreferencesManagerMixin on ChangeNotifier {
  bool _showInlineLyrics = true;
  bool get showInlineLyrics => _showInlineLyrics;

  bool _isCrossfadeEnabled = true;
  bool get isCrossfadeEnabled => _isCrossfadeEnabled;

  bool _showVisualizer = true;
  bool get showVisualizer => _showVisualizer;

  Future<void> initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isCrossfadeEnabled = prefs.getBool('enable_crossfade') ?? true;
    _showVisualizer = prefs.getBool('show_visualizer') ?? true;
    _showInlineLyrics = prefs.getBool('show_inline_lyrics') ?? true;
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
}
