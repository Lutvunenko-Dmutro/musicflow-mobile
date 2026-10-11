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

  // Player
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
