import 'package:music_flow_mobile/l10n/interfaces/app_update_strings.dart';

mixin UkUpdateStrings implements AppUpdateStrings {
  @override
  String get updateDialogTitle => 'Нове оновлення!';

  @override
  String channelSwitchTitle(String channel) => 'Зміна каналу (${channel.toUpperCase()})';

  @override
  String get downloadAndInstall => 'Завантажити та оновити';

  @override
  String get downloadAndSwitch => 'Завантажити та перейти';

  @override
  String get installNow => 'Встановити зараз';

  @override
  String get downloading => 'Завантаження...';

  @override
  String get preparing => 'Підготовка...';

  @override
  String get downloadCompleteOpening => 'Готово! Відкриваємо інсталятор...';

  @override
  String get grantPermissionPrompt => 'Надайте дозвіл на встановлення і натисніть «Встановити зараз»';

  @override
  String get remindLater => 'Нагадати пізніше';

  @override
  String downloadError(String error) => 'Помилка: $error';

  @override
  String whatsNewInVersion(String version) => 'Що нового у v$version:';

  @override
  String missedReleasesCount(int count) => 'пропущено $count';

  @override
  String get missedChanges => 'Пропущені зміни:';

  @override
  String get updateSettingsTitle => 'Оновлення додатку';

  @override
  String get autoCheckTitle => 'Автоматична перевірка';

  @override
  String get autoCheckSubtitle => 'Шукати нові версії у фоновому режимі';

  @override
  String get checkFrequency => 'Частота перевірки';

  @override
  String get systemNotificationsTitle => 'Сповіщення на телефоні';

  @override
  String get systemNotificationsSubtitle => 'Показувати повідомлення у шторці Android';

  @override
  String get updateChannelTitle => 'Канал оновлень';

  @override
  String get channelSwitchNeeded => 'потрібне перемикання';

  @override
  String get checkUpdatesNow => 'Перевірити оновлення зараз';

  @override
  String get checkingUpdates => 'Перевірка оновлень...';

  @override
  String get latestVersionInstalled => 'У вас встановлена найновіша версія! 🎉';

  @override
  String get channelChangeDialogTitle => 'Зміна каналу оновлень';

  @override
  String channelChangePrompt(String channel) =>
      'Ви обрали канал $channel.\n\nБажаєте зараз завантажити та встановити відповідну збірку?';

  @override
  String get later => 'Пізніше';

  @override
  String get downloadNow => 'Завантажити зараз';

  @override
  String updateNotificationTitle(String version) => 'Доступне оновлення MusicFlow v$version';

  @override
  String get updateNotificationBody => 'Натисніть, щоб переглянути нові функції та оновити додаток';

  @override
  String get freqOnLaunch => 'При кожному запуску';

  @override
  String get freqDaily => 'Раз на день';

  @override
  String get freqWeekly => 'Раз на тиждень';

  @override
  String get freqManual => 'Лише вручну';

  @override
  String get channelRelease => 'Release (Швидкий, ~65 МБ)';

  @override
  String get channelDebug => 'Debug (Розробка, ~217 МБ)';

  @override
  String get defaultChangelogFallback => 'Покращення стабільності та оптимізація додатку';

  @override
  String get devServerDefaultPreset => 'За замовчуванням';
}
