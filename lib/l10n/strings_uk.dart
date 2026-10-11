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

  // Player
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
