import 'package:music_flow_mobile/l10n/app_strings.dart';

class StringsEn implements AppStrings {
  const StringsEn();

  // Navigation
  @override
  String get search => 'Search';
  @override
  String get library => 'Library';
  @override
  String get history => 'History';
  @override
  String get settings => 'Settings';

  // Player & Menu
  @override
  String get nowPlaying => 'Now Playing';
  @override
  String get queue => 'Queue';
  @override
  String get visualizer => 'Visualizer';
  @override
  String get equalizer => 'Equalizer';
  @override
  String get shuffle => 'Shuffle';
  @override
  String get repeat => 'Repeat';
  @override
  String get searchKaraoke => 'Find other karaoke';
  @override
  String get showMiniKaraoke => 'Show mini-karaoke';
  @override
  String get hideMiniKaraoke => 'Hide mini-karaoke';
  @override
  String get showVisualizer => 'Show visualizer';
  @override
  String get hideVisualizer => 'Hide visualizer';
  @override
  String get visualizerSettings => 'Visualizer settings';
  @override
  String get sleepTimer => 'Sleep timer';
  @override
  String get sleepTimerDesc => 'Music will stop automatically after selected time.';
  @override
  String get sleepTimerActiveUntil => 'Timer active until';
  @override
  String get turnOffTimer => 'Turn off timer';
  @override
  String get minutesSuffix => 'minutes';
  @override
  String get timerSetTo => 'Timer set to';

  // Visualizer Appearance & Positioning
  @override
  String get visualizerAppearance => 'Appearance & Position';
  @override
  String get visualizerPlacement => 'Placement';
  @override
  String get visPosBottom => 'Bottom strip';
  @override
  String get visPosCoverAura => 'Around album cover';
  @override
  String get visCoverShape => 'Cover Shape';
  @override
  String get visShapeSquare => 'Rounded square';
  @override
  String get visShapeVinyl => 'Circular vinyl';
  @override
  String get visColorTheme => 'Color Palette';
  @override
  String get visColorFire => 'MusicFlow Fire';
  @override
  String get visColorAdaptive => 'Album adaptive';
  @override
  String get visColorCyberpunk => 'Cyber-neon';

  // Settings
  @override
  String get settingsTitle => 'Settings';
  @override
  String get playback => 'Playback';
  @override
  String get crossfadeTitle => 'Smooth Crossfade';
  @override
  String get crossfadeSubtitle => 'Seamless fade in and fade out between songs';
  @override
  String get smoothMediaPauseTitle => 'Smooth pause during media playback';
  @override
  String get smoothMediaPauseSubtitle =>
      'Smoothly fade audio and pause when YouTube or other video starts';
  @override
  String get visualizerSubtitle => 'Live preview, styles and animation parameters';
  @override
  String get equalizerSubtitle => 'Frequency bands, bass boost and presets';
  @override
  String get system => 'System';
  @override
  String get language => 'Language';
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get mediaNotificationTitle => 'Show player notification';
  @override
  String get mediaNotificationSubtitle => 'Disabling may stop background music playback';
  @override
  String get downloadFolderTitle => 'Download folder';
  @override
  String get defaultFolder => 'Default (Internal Storage)';
  @override
  String get downloadSettingsTitle => 'Download Options';
  @override
  String get embedLyricsTitle => 'Embed Lyrics';
  @override
  String get embedLyricsSubtitle => 'Automatically fetch lyrics and save into file';
  @override
  String get highQualityTitle => 'Best Audio Quality';
  @override
  String get highQualitySubtitle => 'Download highest bitrate available (uses more storage)';
  @override
  String get privacyAndDiagnostics => 'Privacy & Diagnostics';
  @override
  String get crashConsentTitle => 'Consent to crash reports';
  @override
  String get crashConsentSubtitle =>
      'Anonymously send crash reports to developer for fast issue resolution';

  // Search
  @override
  String get searchPrompt => 'Search tracks or paste YouTube link';
  @override
  String get searchPlaceholder => 'Enter title or link...';
  @override
  String get searchPasteTooltip => 'Paste from clipboard';
  @override
  String get searchButton => 'Search';
  @override
  String get filter => 'Filter';
  @override
  String get inLibrary => 'In Library';
  @override
  String get searchingYoutube => 'Searching tracks on YouTube...';
  @override
  String get nothingFound => 'Nothing found';
  @override
  String get nothingFoundHint => 'Try changing search query or reset filters';

  // Library & History
  @override
  String get selected => 'selected';
  @override
  String get sortDirection => 'Change direction';
  @override
  String get sortByTitle => 'By title';
  @override
  String get sortByArtist => 'By artist';
  @override
  String get sortByDate => 'By date added';
  @override
  String get refresh => 'Refresh';
  @override
  String get deleteSelected => 'Delete selected';
  @override
  String get emptyHistory => 'You have not listened to anything yet';
  @override
  String get emptyLibrary => 'No tracks in your library yet';

  // Dialogs & Actions
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Retry';
}
