import 'package:music_flow_mobile/l10n/interfaces/app_general_settings_strings.dart';

mixin EnGeneralSettingsStrings implements AppGeneralSettingsStrings {
  @override
  String get defaultFolder => 'Default (Internal Storage)';
  @override
  String folderChangedTo(String path) => 'Folder changed to: $path';
  @override
  String get downloadSettingsTitle => 'Download Options';
  @override
  String get embedLyricsTitle => 'Embed lyrics';
  @override
  String get embedLyricsSubtitle => 'Automatically fetch lyrics and embed into file';
  @override
  String get highQualityTitle => 'Best audio quality';
  @override
  String get highQualitySubtitle => 'Download highest bitrate (uses more storage)';
  @override
  String get privacyAndDiagnostics => 'Privacy & Diagnostics';
  @override
  String get crashConsentTitle => 'Crash reporting consent';
  @override
  String get crashConsentSubtitle =>
      'Anonymously share crash reports to help developer fix issues quickly';
}
