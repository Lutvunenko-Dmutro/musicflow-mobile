import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/l10n/app_language.dart';
import 'package:music_flow_mobile/l10n/strings_uk.dart';
import 'package:music_flow_mobile/l10n/strings_en.dart';
import 'package:music_flow_mobile/providers/language_provider.dart';

abstract class AppStrings {
  // Navigation
  String get search;
  String get library;
  String get history;
  String get settings;

  // Player
  String get nowPlaying;
  String get queue;
  String get visualizer;
  String get equalizer;
  String get shuffle;
  String get repeat;

  // Settings
  String get settingsTitle;
  String get playback;
  String get crossfadeTitle;
  String get crossfadeSubtitle;
  String get smoothMediaPauseTitle;
  String get smoothMediaPauseSubtitle;
  String get visualizerSubtitle;
  String get equalizerSubtitle;
  String get system;
  String get language;
  String get selectLanguage;
  String get mediaNotificationTitle;
  String get mediaNotificationSubtitle;
  String get downloadFolderTitle;
  String get defaultFolder;

  // Dialogs & Actions
  String get cancel;
  String get save;
  String get close;
  String get retry;

  static AppStrings get(AppLanguage language) {
    switch (language) {
      case AppLanguage.uk:
        return const StringsUk();
      case AppLanguage.en:
        return const StringsEn();
    }
  }

  static AppStrings of(BuildContext context, {bool listen = true}) {
    return Provider.of<LanguageProvider>(context, listen: listen).strings;
  }
}

extension LocalizationExtension on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
