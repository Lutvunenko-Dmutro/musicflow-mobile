import 'package:music_flow_mobile/l10n/interfaces/app_permission_strings.dart';

mixin EnPermissionStrings implements AppPermissionStrings {
  @override
  String get splashTagline => 'Your music. Your rhythm.';

  @override
  String get permissionsTitle => 'Permission Setup';

  @override
  String get permissionsSubtitle =>
      'To enable background playback, visualizer and media features, please grant permissions:';

  @override
  String get continueButton => 'Continue';

  @override
  String get skipToMusic => 'Skip to Music';

  @override
  String get permissionGranted => 'Granted';

  @override
  String get permissionGrant => 'Grant';

  @override
  String get notificationPermTitle => 'Notifications & Player';

  @override
  String get notificationPermDesc =>
      'Control playback from status bar and lockscreen';

  @override
  String get visualizerPermTitle => 'FFT Visualizer';

  @override
  String get visualizerPermDesc =>
      'Hardware frequency capture for 60 FPS spectrum animation';

  @override
  String get storagePermTitle => 'Library & Audio Files';

  @override
  String get storagePermDesc =>
      'Access local audio files and downloaded tracks';

  @override
  String get updatePermTitle => '1-Click Updates';

  @override
  String get updatePermDesc =>
      'Secure installation of app releases directly';
}
