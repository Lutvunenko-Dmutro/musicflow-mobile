import 'package:music_flow_mobile/l10n/interfaces/app_general_settings_strings.dart';

mixin UkGeneralSettingsStrings implements AppGeneralSettingsStrings {
  @override
  String get defaultFolder => 'За замовчуванням (Внутрішня пам\'ять)';
  @override
  String folderChangedTo(String path) => 'Папку змінено на: $path';
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
}
