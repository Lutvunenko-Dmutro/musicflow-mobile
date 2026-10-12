import 'package:music_flow_mobile/l10n/interfaces/app_search_filter_strings.dart';

mixin EnSearchFilterStrings implements AppSearchFilterStrings {
  @override
  String get filterSheetTitle => 'Filters';
  @override
  String get resetFilters => 'Reset';
  @override
  String get applyFilters => 'Apply filters';
  @override
  String get contentFormatHeader => 'Content format';
  @override
  String get formatAll => 'Any';
  @override
  String get formatStudio => '🎵 Studio audio';
  @override
  String get formatClip => '🎬 Video clip';
  @override
  String get formatLive => '🎤 Live';
  @override
  String get formatAcoustic => '🎸 Acoustic';
  @override
  String get formatRemix => '🎛️ Remix';
  @override
  String get countryLanguageHeader => 'Country / Language';
  @override
  String get regionAll => 'All languages';
  @override
  String get regionUa => '🇺🇦 Ukrainian';
  @override
  String get regionGlobal => '🌍 Global';
  @override
  String get regionRu => 'Russian';
  @override
  String get regionKpop => '🇯🇵 K-Pop';
  @override
  String get regionLatino => '🇪🇸 Latin';
  @override
  String get genreHeader => 'Genre';
  @override
  String get genreAll => 'All genres';
  @override
  String get genreRock => '🎸 Rock';
  @override
  String get genrePop => '🎤 Pop';
  @override
  String get genreElectronic => '🎧 Electronic';
  @override
  String get genreRap => '🕶️ Rap';
  @override
  String get genreLofi => '☕ Lo-Fi';
  @override
  String get durationHeader => 'Duration';
  @override
  String get durationAny => 'Any';
  @override
  String get durationUnder5 => 'Under 5 min';
  @override
  String get durationUnder10 => 'Under 10 min';
  @override
  String get durationOver10 => 'Sets (>10 min)';
  @override
  String get sortHeader => 'Sort by';
  @override
  String get sortRelevance => '🔥 Relevance';
  @override
  String get sortViews => '👁️ Views';
  @override
  String get sortNewest => '🆕 Newest';
  @override
  String get searchErrorGeneric => 'Search error.';
  @override
  String get searchErrorNoInternet => 'No internet connection.';
}
