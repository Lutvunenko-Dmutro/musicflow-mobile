import 'package:music_flow_mobile/l10n/interfaces/app_update_strings.dart';

mixin EnUpdateStrings implements AppUpdateStrings {
  @override
  String get updateDialogTitle => 'New Update Available!';

  @override
  String channelSwitchTitle(String channel) => 'Channel Switch (${channel.toUpperCase()})';

  @override
  String get downloadAndInstall => 'Download & Update';

  @override
  String get downloadAndSwitch => 'Download & Switch';

  @override
  String get installNow => 'Install Now';

  @override
  String get downloading => 'Downloading...';

  @override
  String get preparing => 'Preparing...';

  @override
  String get downloadCompleteOpening => 'Done! Opening installer...';

  @override
  String get grantPermissionPrompt => 'Grant install permission and tap "Install Now"';

  @override
  String get remindLater => 'Remind Later';

  @override
  String downloadError(String error) => 'Error: $error';

  @override
  String whatsNewInVersion(String version) => 'What\'s new in v$version:';

  @override
  String missedReleasesCount(int count) => 'missed $count';

  @override
  String get missedChanges => 'Missed Changes:';

  @override
  String get updateSettingsTitle => 'App Updates';

  @override
  String get autoCheckTitle => 'Automatic Check';

  @override
  String get autoCheckSubtitle => 'Check for new versions in background';

  @override
  String get checkFrequency => 'Check Frequency';

  @override
  String get systemNotificationsTitle => 'System Notifications';

  @override
  String get systemNotificationsSubtitle => 'Show notifications in Android shade';

  @override
  String get updateChannelTitle => 'Update Channel';

  @override
  String get channelSwitchNeeded => 'switch required';

  @override
  String get checkUpdatesNow => 'Check for updates now';

  @override
  String get checkingUpdates => 'Checking for updates...';

  @override
  String get latestVersionInstalled => 'You have the latest version installed! 🎉';

  @override
  String get channelChangeDialogTitle => 'Change Update Channel';

  @override
  String channelChangePrompt(String channel) =>
      'You selected channel $channel.\n\nDo you want to download and install this build now?';

  @override
  String get later => 'Later';

  @override
  String get downloadNow => 'Download Now';

  @override
  String updateNotificationTitle(String version) => 'MusicFlow update v$version available';

  @override
  String get updateNotificationBody => 'Tap to review new features and update the app';

  @override
  String get freqOnLaunch => 'On every launch';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqManual => 'Manual only';

  @override
  String get channelRelease => 'Release (Fast, ~65 MB)';

  @override
  String get channelDebug => 'Debug (Development, ~217 MB)';

  @override
  String get defaultChangelogFallback => 'Stability improvements and app optimization';

  @override
  String get devServerDefaultPreset => 'Default';
}
