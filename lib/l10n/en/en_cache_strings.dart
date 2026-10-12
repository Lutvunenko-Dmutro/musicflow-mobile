import 'package:music_flow_mobile/l10n/interfaces/app_cache_strings.dart';

mixin EnCacheStrings implements AppCacheStrings {
  @override
  String get storageAndDataTitle => 'Storage & Data';
  @override
  String get refreshTooltip => 'Refresh';
  @override
  String totalOccupied(String formattedBytes) => 'Total occupied: $formattedBytes';
  @override
  String get tempCoversTitle => 'Covers & Temp Files';
  @override
  String tempCoversSubtitle(int count) => '$count files in temp';
  @override
  String get clearTempTooltip => 'Delete temporary covers only';
  @override
  String get lyricsCacheTitle => 'Song Lyrics (LRC)';
  @override
  String lyricsCacheSubtitle(int count) => '$count cached';
  @override
  String get clearLyricsTooltip => 'Delete cached lyrics only';
  @override
  String get dbTagsTitle => 'Database Tags Cache';
  @override
  String get dbTagsSubtitle => 'Local songs index';
  @override
  String get clearDbTooltip => 'Reset song tags index';
  @override
  String get historyCacheTitle => 'Playback History';
  @override
  String historyCacheSubtitle(int count) => '$count tracks in History';
  @override
  String historyItemsCount(int count) => '$count pcs.';
  @override
  String get clearHistoryTooltip => 'Clear playback history only';
  @override
  String get clearAllTempCache => 'Clear all temporary cache';
  @override
  String get clearTempDialogTitle => 'Clear covers?';
  @override
  String get clearTempDialogMsg => 'This will delete temporary cover files. Downloaded audio files remain untouched.';
  @override
  String get clearTempSuccess => '✅ Temporary covers and files cleared!';
  @override
  String get clearLyricsDialogTitle => 'Clear song lyrics?';
  @override
  String get clearLyricsDialogMsg => 'This will delete cached lyrics. They will be re-downloaded when opened online.';
  @override
  String get clearLyricsSuccess => '✅ Saved lyrics cache cleared!';
  @override
  String get clearDbDialogTitle => 'Reset tag index?';
  @override
  String get clearDbDialogMsg => 'This clears the local tag cache. The player will rescan files when you open the library. Songs will not be deleted.';
  @override
  String get clearDbSuccess => '✅ Local song metadata cache cleared!';
  @override
  String get clearHistoryDialogTitle => 'Clear history?';
  @override
  String get clearHistoryDialogMsg => 'This deletes all entries from the History tab. Downloaded tracks and cache remain untouched.';
  @override
  String get clearHistorySuccess => '✅ Playback history cleared!';
  @override
  String get clearAllDialogTitle => 'Clear all cache?';
  @override
  String get clearAllDialogMsg => 'Temporary covers, cached lyrics, and tag index will be cleared. Downloaded songs and history will remain intact.';
  @override
  String get clearAllSuccess => '✅ All cache cleared successfully!';
  @override
  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  @override
  String get devServerTitle => 'Server Settings (Dev Mode)';
  @override
  String get devServerSubtitle => 'Telemetry and logs server address:';
  @override
  String devServerConnected(String url) => '✅ Connected to server: $url';
  @override
  String devServerUnreachable(String url) => '⚠️ Server saved, but unreachable: $url';
}
