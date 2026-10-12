import 'package:music_flow_mobile/l10n/interfaces/app_search_filter_strings.dart';

mixin UkSearchFilterStrings implements AppSearchFilterStrings {
  @override
  String get filterSheetTitle => 'Фільтр';
  @override
  String get resetFilters => 'Скинути';
  @override
  String get applyFilters => 'Застосувати фільтри';
  @override
  String get contentFormatHeader => 'Формат контенту';
  @override
  String get formatAll => 'Будь-який';
  @override
  String get formatStudio => '🎵 Студійне аудіо';
  @override
  String get formatClip => '🎬 Кліп';
  @override
  String get formatLive => '🎤 Live';
  @override
  String get formatAcoustic => '🎸 Акустика';
  @override
  String get formatRemix => '🎛️ Ремікс';
  @override
  String get countryLanguageHeader => 'Країна / Мова';
  @override
  String get regionAll => 'Всі мови';
  @override
  String get regionUa => '🇺🇦 Українська';
  @override
  String get regionGlobal => '🌍 Зарубіжна';
  @override
  String get regionRu => 'Російська';
  @override
  String get regionKpop => '🇯🇵 K-Pop';
  @override
  String get regionLatino => '🇪🇸 Латина';
  @override
  String get genreHeader => 'Жанр';
  @override
  String get genreAll => 'Всі жанри';
  @override
  String get genreRock => '🎸 Рок';
  @override
  String get genrePop => '🎤 Поп';
  @override
  String get genreElectronic => '🎧 Електроніка';
  @override
  String get genreRap => '🕶️ Реп';
  @override
  String get genreLofi => '☕ Lo-Fi';
  @override
  String get durationHeader => 'Тривалість';
  @override
  String get durationAny => 'Будь-яка';
  @override
  String get durationUnder5 => 'До 5 хв';
  @override
  String get durationUnder10 => 'До 10 хв';
  @override
  String get durationOver10 => 'Сети (>10 хв)';
  @override
  String get sortHeader => 'Сортування';
  @override
  String get sortRelevance => '🔥 За релевантністю';
  @override
  String get sortViews => '👁️ За переглядами';
  @override
  String get sortNewest => '🆕 Найновіші';
  @override
  String get searchErrorGeneric => 'Помилка пошуку.';
  @override
  String get searchErrorNoInternet => 'Немає підключення до інтернету.';
}
