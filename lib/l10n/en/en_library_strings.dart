import 'package:music_flow_mobile/l10n/interfaces/app_library_strings.dart';

mixin EnLibraryStrings implements AppLibraryStrings {
  @override
  String get queueTitle => 'Playback Queue';
  @override
  String get queueEmpty => 'Queue is empty';
  @override
  String get noMusicPlaying => 'No music playing';
  @override
  String daysAgo(int days) => '$days d ago';
  @override
  String hoursAgo(int hours) => '$hours h ago';
  @override
  String minutesAgo(int minutes) => '$minutes min ago';
  @override
  String get justNow => 'Just now';
  @override
  String get deleteSongsDialogTitle => 'Delete songs?';
  @override
  String deleteSongsDialogMsg(int count) => 'Are you sure you want to delete $count songs?';
  @override
  String get deleteFromHistoryTitle => 'Delete from history';
  @override
  String deleteFromHistoryMsg(int count) => 'Delete $count ${count == 1 ? 'track' : 'tracks'} from history?';
  @override
  String get selectAll => 'Select all';
  @override
  String get deselectAll => 'Deselect all';
  @override
  String get playerPlaybackErrorRetry => 'Tap to retry';
}
