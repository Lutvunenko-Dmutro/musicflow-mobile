import 'package:music_flow_mobile/l10n/interfaces/app_common_actions_strings.dart';

mixin UkCommonActionsStrings implements AppCommonActionsStrings {
  @override
  String get cancel => 'Скасувати';

  @override
  String get save => 'Зберегти';

  @override
  String get close => 'Закрити';

  @override
  String get retry => 'Повторити';

  @override
  String get reset => 'Скинути';

  @override
  String get delete => 'Видалити';

  @override
  String get no => 'Ні';

  @override
  String get missingFileTitle => 'Файл відсутній';

  @override
  String get missingFileContent =>
      'Цей аудіофайл було видалено з пристрою. Бажаєте видалити цей запис з історії?';

  @override
  String get noInternetConnection => 'Немає підключення до інтернету.';

  @override
  String get trackBlockedYouTube =>
      'Цей трек заблоковано на YouTube (обмеження правовласника). Спробуйте іншу версію.';

  @override
  String get download => 'Завантажити';

  @override
  String downloadSongPrompt(String title) => 'Завантажити пісню "$title" на пристрій?';

  @override
  String downloadStarted(String title) => 'Завантаження: $title';

  @override
  String get fileAlreadyExists => 'Файл вже існує';

  @override
  String get fileAlreadyExistsPrompt =>
      'Ця пісня вже завантажена. Бажаєте завантажити її знову (перезаписати)?';

  @override
  String get overwrite => 'Перезаписати';

  @override
  String get connecting => "З'єднання...";

  @override
  String get calculating => 'Обчислення...';

  @override
  String get alreadyDownloaded => 'Вже завантажено';

  @override
  String get errorLabel => 'Помилка';
}
