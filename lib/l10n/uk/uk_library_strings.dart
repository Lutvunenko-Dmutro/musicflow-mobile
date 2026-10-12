import 'package:music_flow_mobile/l10n/interfaces/app_library_strings.dart';

mixin UkLibraryStrings implements AppLibraryStrings {
  @override
  String get queueTitle => 'Черга відтворення';
  @override
  String get queueEmpty => 'Черга порожня';
  @override
  String get noMusicPlaying => 'Музика не грає';
  @override
  String daysAgo(int days) => '$days дн. тому';
  @override
  String hoursAgo(int hours) => '$hours год. тому';
  @override
  String minutesAgo(int minutes) => '$minutes хв. тому';
  @override
  String get justNow => 'Щойно';
  @override
  String get deleteSongsDialogTitle => 'Видалити пісні?';
  @override
  String deleteSongsDialogMsg(int count) => 'Ви впевнені, що хочете видалити $count пісень?';
  @override
  String get deleteFromHistoryTitle => 'Видалити з історії';
  @override
  String deleteFromHistoryMsg(int count) => 'Видалити $count ${count == 1 ? 'трек' : 'треків'} з історії?';
  @override
  String get selectAll => 'Вибрати все';
  @override
  String get deselectAll => 'Зняти все';
  @override
  String get playerPlaybackErrorRetry => 'Натисніть для повтору';
}
