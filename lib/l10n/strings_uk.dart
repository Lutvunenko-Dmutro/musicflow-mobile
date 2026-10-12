import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_update_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_permission_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_visualizer_detailed_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_equalizer_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_common_actions_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_search_filter_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_cache_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_lyrics_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_library_strings.dart';
import 'package:music_flow_mobile/l10n/uk/uk_general_settings_strings.dart';

class StringsUk
    with
        UkUpdateStrings,
        UkPermissionStrings,
        UkVisualizerDetailedStrings,
        UkEqualizerStrings,
        UkCommonActionsStrings,
        UkSearchFilterStrings,
        UkCacheStrings,
        UkLyricsStrings,
        UkLibraryStrings,
        UkGeneralSettingsStrings
    implements AppStrings {
  const StringsUk();

  // Navigation
  @override
  String get search => 'Пошук';
  @override
  String get library => 'Медіатека';
  @override
  String get history => 'Історія';
  @override
  String get settings => 'Налаштування';

  // Player & Menu
  @override
  String get nowPlaying => 'Зараз грає';
  @override
  String get queue => 'Черга';
  @override
  String get visualizer => 'Візуалізатор';
  @override
  String get equalizer => 'Еквалайзер';
  @override
  String get shuffle => 'Випадково';
  @override
  String get repeat => 'Повтор';
  @override
  String get searchKaraoke => 'Знайти інше караоке';
  @override
  String get showMiniKaraoke => 'Показати міні-караоке';
  @override
  String get hideMiniKaraoke => 'Приховати міні-караоке';
  @override
  String get showVisualizer => 'Показати візуалізатор';
  @override
  String get hideVisualizer => 'Приховати візуалізатор';
  @override
  String get visualizerSettings => 'Налаштування візуалізатора';
  @override
  String get sleepTimer => 'Таймер сну';
  @override
  String get sleepTimerDesc => 'Музика автоматично зупиниться через обраний час.';
  @override
  String get sleepTimerActiveUntil => 'Таймер активний до';
  @override
  String get turnOffTimer => 'Вимкнути таймер';
  @override
  String get minutesSuffix => 'хв';
  @override
  String get timerSetTo => 'Таймер встановлено на';

  // Visualizer Appearance & Positioning
  @override
  String get visualizerAppearance => 'Зовнішній вигляд візуалізатора';
  @override
  String get visualizerPlacement => 'Розташування';
  @override
  String get visPosBottom => 'Знизу плеєра';
  @override
  String get visPosCoverAura => 'Аура навколо обкладинки';
  @override
  String get visCoverShape => 'Форма обкладинки';
  @override
  String get visShapeSquare => 'Квадратна';
  @override
  String get visShapeVinyl => 'Вініловий диск';
  @override
  String get visColorTheme => 'Кольорова схема';
  @override
  String get visColorFire => 'Фірмова (Мультиколір)';
  @override
  String get visColorAdaptive => 'Адаптивна (Колір теми)';
  @override
  String get visSpectrumMode => 'Режим спектра аури';
  @override
  String get visSpectrumLive => 'Живий 360°';
  @override
  String get visSpectrumMirror2H => 'Дзеркало (Ліво-Право)';
  @override
  String get visSpectrumMirror2V => 'Дзеркало (Верх-Низ)';
  @override
  String get visSpectrumPulse4 => 'Пульс 4 сторін';

  // Settings
  @override
  String get settingsTitle => 'Налаштування';
  @override
  String get playback => 'Відтворення';
  @override
  String get crossfadeTitle => 'Плавне згасання (Crossfade)';
  @override
  String get crossfadeSubtitle => 'Плавний перехід між піснями';
  @override
  String get smoothMediaPauseTitle => 'Плавне згасання при паузі';
  @override
  String get smoothMediaPauseSubtitle => 'М\'яке зменшення гучності замість різкої зупинки';
  @override
  String get visualizerSubtitle => 'Стиль хвиль, частота та чутливість';
  @override
  String get equalizerSubtitle => '5 смуг, бас-буст та 3D-звук';
  @override
  String get system => 'Система';
  @override
  String get language => 'Мова інтерфейсу';
  @override
  String get selectLanguage => 'Вибір мови';
  @override
  String get mediaNotificationTitle => 'Повідомлення з плеєром';
  @override
  String get mediaNotificationSubtitle => 'Керування відтворенням у шторці';
  @override
  String get downloadFolderTitle => 'Папка для завантажень';

  // Search
  @override
  String get searchPrompt => 'Пошук треків або посилання з YouTube';
  @override
  String get searchPlaceholder => 'Введіть назву або посилання...';
  @override
  String get searchPasteTooltip => 'Вставити з буфера';
  @override
  String get searchButton => 'Пошук';
  @override
  String get filter => 'Фільтр';
  @override
  String get inLibrary => 'В бібліотеці';
  @override
  String get searchingYoutube => 'Пошук треків на YouTube...';
  @override
  String get nothingFound => 'Нічого не знайдено';
  @override
  String get nothingFoundHint => 'Спробуйте змінити пошуковий запит або скинути фільтри';

  // Library & History
  @override
  String get selected => 'вибрано';
  @override
  String get sortDirection => 'Змінити напрямок';
  @override
  String get sortByTitle => 'За назвою';
  @override
  String get sortByArtist => 'За автором';
  @override
  String get sortByDate => 'За датою додавання';
  @override
  String get refresh => 'Оновити';
  @override
  String get deleteSelected => 'Видалити вибране';
  @override
  String get emptyHistory => 'Ви ще нічого не слухали';
  @override
  String get emptyLibrary => 'У вашій бібліотеці ще немає треків';
}
