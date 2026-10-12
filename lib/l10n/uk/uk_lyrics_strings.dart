import 'package:music_flow_mobile/l10n/interfaces/app_lyrics_strings.dart';

mixin UkLyricsStrings implements AppLyricsStrings {
  @override
  String get lyricsDefaultTitle => 'Текст пісні';
  @override
  String get lyricsNotFound => 'Текст пісні не знайдено';
  @override
  String get lyricsLoading => 'Завантаження караоке та тексту...';
  @override
  String get lyricsDisabledForSong => 'Субтитри вимкнено для цієї пісні';
  @override
  String get lyricsSettingsSavedForTrack => 'Налаштування збережено для цього треку';
  @override
  String get enableLyricsForSong => 'Увімкнути субтитри для пісні';
  @override
  String get disableLyricsForSong => 'Без субтитрів для цієї пісні';
  @override
  String get lyricsEnabledSnackbar => 'Субтитри увімкнено для цієї пісні';
  @override
  String get lyricsDisabledSnackbar => 'Збережено: цю пісню залишено без субтитрів';
  @override
  String get searchKaraokeDatabase => 'Знайти караоке в базі';
  @override
  String get manageLyricsVersionsTooltip => 'Керування версіями субтитрів';
  @override
  String get lyricsVersionsSheetTitle => 'Версії субтитрів та караоке';
  @override
  String get lyricsVersionsButton => 'Версії';
  @override
  String get lyricsDisabledOptionTitle => 'Без субтитрів (Вимкнено)';
  @override
  String get lyricsDisabledOptionSubtitle => 'Приховати текст для цієї пісні';
  @override
  String get syncedLyricsSubtitle => 'Синхронізований текст під музику';
  @override
  String get staticLyricsSubtitle => 'Статичний текст пісні';
  @override
  String get karaokeBadge => '⏱️ Караоке';
  @override
  String get staticTextBadge => '📄 Текст';
  @override
  String get searchAnotherKaraoke => 'Знайти інше караоке в базі';
  @override
  String deleteLyricsVersionDialogTitle(String key) => 'Видалити "$key"?';
  @override
  String get deleteLyricsVersionButton => 'Видалити версію';
  @override
  String resetKaraokeDialogTitle(String title) => 'Скинути версії для "$title"?';
  @override
  String get resetKaraokeButton => 'Скинути караоке';
  @override
  String get searchLyricsPromptTitle => 'Пошук караоке та слів';
  @override
  String get searchLyricsHint => 'Виконавець або назва...';
  @override
  String get searchButtonShort => 'Пошук';
  @override
  String searchAllCount(int count) => 'Всі ($count)';
  @override
  String searchKaraokeCount(int count) => '⏱️ Караоке ($count)';
  @override
  String searchTextCount(int count) => '📄 Текст ($count)';
  @override
  String get searchingLrclib => 'Шукаємо караоке в базі LRCLIB...';
  @override
  String get lrclibEmpty => 'Нічого не знайдено. Спробуйте змінити запит.';
  @override
  String get lrclibSearchError => 'Помилка пошуку. Перевірте зв\'язок.';
  @override
  String lrclibSavedSnackbar(String artist, String title) => 'Збережено караоке з LRCLIB: $artist - $title';
  @override
  String get previewLyrics => 'Переглянути';
  @override
  String get selectLyrics => 'Вибрати';
  @override
  String get backAction => 'Назад';
  @override
  String get saveKaraokeAction => 'Зберегти це караоке';
  @override
  String get saveTextAction => 'Зберегти цей текст';
  @override
  String lyricsSourceLrclib(String id) => 'Джерело: LRCLIB (#$id)';
  @override
  String formatLyricsTrackKey(String key) => key;
  @override
  String get lyricsLoadError => 'Помилка завантаження тексту.';
}
