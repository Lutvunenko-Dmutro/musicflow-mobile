import 'package:music_flow_mobile/l10n/interfaces/app_cache_strings.dart';

mixin UkCacheStrings implements AppCacheStrings {
  @override
  String get storageAndDataTitle => 'Сховище та дані';
  @override
  String get refreshTooltip => 'Оновити';
  @override
  String totalOccupied(String formattedBytes) => 'Всього зайнято: $formattedBytes';
  @override
  String get tempCoversTitle => 'Обкладинки та файли';
  @override
  String tempCoversSubtitle(int count) => '$count файлів у temp';
  @override
  String get clearTempTooltip => 'Видалити тільки тимчасові обкладинки';
  @override
  String get lyricsCacheTitle => 'Тексти пісень (LRC)';
  @override
  String lyricsCacheSubtitle(int count) => '$count закешовано';
  @override
  String get clearLyricsTooltip => 'Видалити тільки збережені тексти';
  @override
  String get dbTagsTitle => 'Кеш тегів бази даних';
  @override
  String get dbTagsSubtitle => 'Індекс локальних пісень';
  @override
  String get clearDbTooltip => 'Скинути індекс тегів пісень';
  @override
  String get historyCacheTitle => 'Історія прослуховувань';
  @override
  String historyCacheSubtitle(int count) => '$count треків у вкладці "Історія"';
  @override
  String historyItemsCount(int count) => '$count шт.';
  @override
  String get clearHistoryTooltip => 'Видалити тільки історію прослуховувань';
  @override
  String get clearAllTempCache => 'Очистити весь тимчасовий кеш';
  @override
  String get clearTempDialogTitle => 'Очистити обкладинки?';
  @override
  String get clearTempDialogMsg => 'Це видалить тимчасові файли обкладинок. Самі аудіофайли пісень залишаться недоторканими.';
  @override
  String get clearTempSuccess => '✅ Тимчасові обкладинки та файли очищено!';
  @override
  String get clearLyricsDialogTitle => 'Очистити тексти пісень?';
  @override
  String get clearLyricsDialogMsg => 'Це видалить закешовані тексти. Вони завантажаться заново при відкритті пісень з інтернету.';
  @override
  String get clearLyricsSuccess => '✅ Збережені тексти пісень очищено!';
  @override
  String get clearDbDialogTitle => 'Скинути індекс тегів?';
  @override
  String get clearDbDialogMsg => 'Це очистить локальний кеш тегів. Плеєр просто пересканує файли при наступному вході в бібліотеку. Самі пісні не видаляються.';
  @override
  String get clearDbSuccess => '✅ Кеш метаданих локальних пісень очищено!';
  @override
  String get clearHistoryDialogTitle => 'Очистити історію?';
  @override
  String get clearHistoryDialogMsg => 'Це видалить усі записи з вкладки "Історія". Самі завантажені пісні та кеш залишаться недоторканими.';
  @override
  String get clearHistorySuccess => '✅ Історію прослуховувань очищено!';
  @override
  String get clearAllDialogTitle => 'Очистити весь кеш?';
  @override
  String get clearAllDialogMsg => 'Будуть очищені тимчасові файли обкладинок, збережені тексти пісень та індекс тегів. Всі завантажені пісні та історія залишаться на пристрої.';
  @override
  String get clearAllSuccess => '✅ Весь кеш успішно очищено!';
  @override
  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 Б';
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} МБ';
  }
  @override
  String get devServerTitle => 'Налаштування сервера (Dev Mode)';
  @override
  String get devServerSubtitle => 'Адреса сервера телеметрії та логів:';
  @override
  String devServerConnected(String url) => '✅ Підключено до сервера: $url';
  @override
  String devServerUnreachable(String url) => '⚠️ Сервер збережено, але не відповідає: $url';
}
