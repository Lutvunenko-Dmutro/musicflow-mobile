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

  // Player & Menu
  String get nowPlaying;
  String get queue;
  String get visualizer;
  String get equalizer;
  String get shuffle;
  String get repeat;
  String get searchKaraoke;
  String get showMiniKaraoke;
  String get hideMiniKaraoke;
  String get showVisualizer;
  String get hideVisualizer;
  String get visualizerSettings;
  String get sleepTimer;
  String get sleepTimerDesc;
  String get sleepTimerActiveUntil;
  String get turnOffTimer;
  String get minutesSuffix;
  String get timerSetTo;

  // Visualizer Appearance & Positioning
  String get visualizerAppearance;
  String get visualizerPlacement;
  String get visPosBottom;
  String get visPosCoverAura;
  String get visCoverShape;
  String get visShapeSquare;
  String get visShapeVinyl;
  String get visColorTheme;
  String get visColorFire;
  String get visColorAdaptive;
  String get visColorCyberpunk;

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
  String get downloadSettingsTitle;
  String get embedLyricsTitle;
  String get embedLyricsSubtitle;
  String get highQualityTitle;
  String get highQualitySubtitle;
  String get privacyAndDiagnostics;
  String get crashConsentTitle;
  String get crashConsentSubtitle;

  // Search
  String get searchPrompt;
  String get searchPlaceholder;
  String get searchPasteTooltip;
  String get searchButton;
  String get filter;
  String get inLibrary;
  String get searchingYoutube;
  String get nothingFound;
  String get nothingFoundHint;

  // Library & History
  String get selected;
  String get sortDirection;
  String get sortByTitle;
  String get sortByArtist;
  String get sortByDate;
  String get refresh;
  String get deleteSelected;
  String get emptyHistory;
  String get emptyLibrary;

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
