import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/l10n/app_language.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'app_language';
  static AppLanguage currentAppLanguage = AppLanguage.uk;
  static AppStrings get currentStrings => AppStrings.get(currentAppLanguage);

  AppLanguage _currentLanguage = AppLanguage.uk;
  bool _isInitialized = false;

  LanguageProvider() {
    _loadFromPrefs();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;
  AppStrings get strings => AppStrings.get(_currentLanguage);
  Locale get locale => Locale(_currentLanguage.code);

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code != null) {
        _currentLanguage = AppLanguage.fromCode(code);
        currentAppLanguage = _currentLanguage;
      }
    } catch (_) {
      // Fallback to default
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    currentAppLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (_) {
      // Non-critical persistence failure
    }
  }
}
