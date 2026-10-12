import 'package:music_flow_mobile/l10n/interfaces/app_common_actions_strings.dart';

mixin EnCommonActionsStrings implements AppCommonActionsStrings {
  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get reset => 'Reset';

  @override
  String get delete => 'Delete';

  @override
  String get no => 'No';

  @override
  String get missingFileTitle => 'File Missing';

  @override
  String get missingFileContent =>
      'This audio file was removed from the device. Would you like to remove this entry from history?';

  @override
  String get noInternetConnection => 'No internet connection.';

  @override
  String get trackBlockedYouTube =>
      'This track is restricted on YouTube by the copyright owner. Try another version.';

  @override
  String get download => 'Download';

  @override
  String downloadSongPrompt(String title) => 'Download song "$title" to device?';

  @override
  String downloadStarted(String title) => 'Downloading: $title';

  @override
  String get fileAlreadyExists => 'File already exists';

  @override
  String get fileAlreadyExistsPrompt =>
      'This song is already downloaded. Do you want to download it again (overwrite)?';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get connecting => 'Connecting...';

  @override
  String get calculating => 'Calculating...';

  @override
  String get alreadyDownloaded => 'Already downloaded';

  @override
  String get errorLabel => 'Error';
}
