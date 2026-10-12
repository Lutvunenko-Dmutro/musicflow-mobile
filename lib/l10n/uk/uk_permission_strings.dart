import 'package:music_flow_mobile/l10n/interfaces/app_permission_strings.dart';

mixin UkPermissionStrings implements AppPermissionStrings {
  @override
  String get splashTagline => 'Ваша музика. Ваш ритм.';

  @override
  String get permissionsTitle => 'Налаштування доступу';

  @override
  String get permissionsSubtitle =>
      'Для повноцінної роботи плеєра, візуалізатора та фонового відтворення надайте дозволи:';

  @override
  String get continueButton => 'Продовжити';

  @override
  String get skipToMusic => 'Пропустити та перейти до музики';

  @override
  String get permissionGranted => 'Готово';

  @override
  String get permissionGrant => 'Надати';

  @override
  String get notificationPermTitle => 'Сповіщення та Плеєр';

  @override
  String get notificationPermDesc =>
      'Керування музикою у шторці та на екрані блокування';

  @override
  String get visualizerPermTitle => 'FFT-Візуалізатор';

  @override
  String get visualizerPermDesc =>
      'Апаратне захоплення частот для 60 FPS анімації спектру';

  @override
  String get storagePermTitle => 'Медіатека та Музика';

  @override
  String get storagePermDesc =>
      'Доступ до локальних аудіофайлів та збережених треків';

  @override
  String get updatePermTitle => 'Оновлення в 1 клік';

  @override
  String get updatePermDesc =>
      'Безпечне встановлення нових релізів прямо з додатка';
}
