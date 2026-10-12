import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_update_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_permission_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_visualizer_detailed_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_equalizer_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_common_actions_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_search_filter_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_cache_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_lyrics_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_library_strings.dart';
import 'package:music_flow_mobile/l10n/en/en_general_settings_strings.dart';

class StringsEn
    with
        EnUpdateStrings,
        EnPermissionStrings,
        EnVisualizerDetailedStrings,
        EnEqualizerStrings,
        EnCommonActionsStrings,
        EnSearchFilterStrings,
        EnCacheStrings,
        EnLyricsStrings,
        EnLibraryStrings,
        EnGeneralSettingsStrings
    implements AppStrings {
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
  String get minutesSuffix => 'min';
  @override
  String get timerSetTo => 'Timer set to';

  // Visualizer Appearance & Positioning
  @override
  String get visualizerAppearance => 'Visualizer appearance';
  @override
  String get visualizerPlacement => 'Placement';
  @override
  String get visPosBottom => 'Bottom of player';
  @override
  String get visPosCoverAura => 'Cover Aura';
  @override
  String get visCoverShape => 'Cover shape';
  @override
  String get visShapeSquare => 'Square';
  @override
  String get visShapeVinyl => 'Vinyl record';
  @override
  String get visColorTheme => 'Color scheme';
  @override
  String get visColorFire => 'Brand (Multicolor)';
  @override
  String get visColorAdaptive => 'Adaptive (Theme color)';
  @override
  String get visSpectrumMode => 'Aura Spectrum Mode';
  @override
  String get visSpectrumLive => 'Live 360°';
  @override
  String get visSpectrumMirror2H => 'Mirror (Left-Right)';
  @override
  String get visSpectrumMirror2V => 'Mirror (Top-Bottom)';
  @override
  String get visSpectrumPulse4 => '4-Side Pulse';

  // Settings
  @override
  String get settingsTitle => 'Settings';
  @override
  String get playback => 'Playback';
  @override
  String get crossfadeTitle => 'Crossfade';
  @override
  String get crossfadeSubtitle => 'Smooth transition between songs';
  @override
  String get smoothMediaPauseTitle => 'Smooth pause fade-out';
  @override
  String get smoothMediaPauseSubtitle => 'Soft volume fade-out instead of sudden stop';
  @override
  String get visualizerSubtitle => 'Wave style, rate, and responsiveness';
  @override
  String get equalizerSubtitle => '5 bands, bass boost, and 3D sound';
  @override
  String get system => 'System';
  @override
  String get language => 'Interface language';
  @override
  String get selectLanguage => 'Select language';
  @override
  String get mediaNotificationTitle => 'Media Notification';
  @override
  String get mediaNotificationSubtitle => 'Notification bar playback controls';
  @override
  String get downloadFolderTitle => 'Download folder';

  // Search
  @override
  String get searchPrompt => 'Search tracks or paste YouTube link';
  @override
  String get searchPlaceholder => 'Enter track title or URL...';
  @override
  String get searchPasteTooltip => 'Paste from clipboard';
  @override
  String get searchButton => 'Search';
  @override
  String get filter => 'Filters';
  @override
  String get inLibrary => 'In Library';
  @override
  String get searchingYoutube => 'Searching tracks on YouTube...';
  @override
  String get nothingFound => 'Nothing found';
  @override
  String get nothingFoundHint => 'Try modifying your search or reset filters';

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
}
