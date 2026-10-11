import 'package:music_flow_mobile/l10n/app_strings.dart';

class StringsUk implements AppStrings {
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
  String get minutesSuffix => 'хвилин';
  @override
  String get timerSetTo => 'Таймер встановлено на';

  // Visualizer Appearance & Positioning
  @override
  String get visualizerAppearance => 'Вигляд та позиція';
  @override
  String get visualizerPlacement => 'Розташування';
  @override
  String get visPosBottom => 'Знизу плеєра';
  @override
  String get visPosCoverAura => 'Навколо обкладинки';
  @override
  String get visCoverShape => 'Форма обкладинки';
  @override
  String get visShapeSquare => 'Скруглений квадрат';
  @override
  String get visShapeVinyl => 'Круглий вініл';
  @override
  String get visColorTheme => 'Колірна тема';
  @override
  String get visColorFire => 'MusicFlow Вогонь';
  @override
  String get visColorAdaptive => 'Колір альбому';
  @override
  String get visColorCyberpunk => 'Кібер-неон';

  // Settings
  @override
  String get settingsTitle => 'Налаштування';
  @override
  String get playback => 'Відтворення';
  @override
  String get crossfadeTitle => 'Плавний перехід (Crossfade)';
  @override
  String get crossfadeSubtitle => 'Плавне затихання і перехід між треками';
  @override
  String get smoothMediaPauseTitle => 'Плавна пауза при перегляді медіа';
  @override
  String get smoothMediaPauseSubtitle =>
      'Плавно зменшувати звук і зупиняти музику, якщо вмикається YouTube або інше відео';
  @override
  String get visualizerSubtitle => 'Живий перегляд, стилі та параметри анімації';
  @override
  String get equalizerSubtitle => 'Частотні смуги, бас та пресети';
  @override
  String get system => 'Система';
  @override
  String get language => 'Мова';
  @override
  String get selectLanguage => 'Вибір мови';
  @override
  String get mediaNotificationTitle => 'Показувати сповіщення плеєра';
  @override
  String get mediaNotificationSubtitle => 'Вимкнення може зупиняти фонову музику';
  @override
  String get downloadFolderTitle => 'Папка збереження';
  @override
  String get defaultFolder => 'За замовчуванням (Внутрішня пам\'ять)';
  @override
  String get downloadSettingsTitle => 'Опції завантаження';
  @override
  String get embedLyricsTitle => 'Вшити текст пісні';
  @override
  String get embedLyricsSubtitle => 'Автоматично шукати текст і зберігати у файл';
  @override
  String get highQualityTitle => 'Найкраща якість аудіо';
  @override
  String get highQualitySubtitle => 'Завантажувати найбільший бітрейт (потребує більше пам\'яті)';
  @override
  String get privacyAndDiagnostics => 'Конфіденційність та діагностика';
  @override
  String get crashConsentTitle => 'Згода на збір звітів про помилки';
  @override
  String get crashConsentSubtitle =>
      'Анонімно передавати технічні звіти про збої розробнику для швидкого виправлення помилок';

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

  // Dialogs & Actions
  @override
  String get cancel => 'Скасувати';
  @override
  String get save => 'Зберегти';
  @override
  String get close => 'Закрити';
  @override
  String get retry => 'Повторити';
}
