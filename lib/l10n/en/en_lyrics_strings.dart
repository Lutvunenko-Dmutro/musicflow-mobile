import 'package:music_flow_mobile/l10n/interfaces/app_lyrics_strings.dart';

mixin EnLyricsStrings implements AppLyricsStrings {
  @override
  String get lyricsDefaultTitle => 'Lyrics';
  @override
  String get lyricsNotFound => 'Lyrics not found';
  @override
  String get lyricsLoading => 'Loading lyrics & karaoke...';
  @override
  String get lyricsDisabledForSong => 'Subtitles disabled for this song';
  @override
  String get lyricsSettingsSavedForTrack => 'Preference saved for this track';
  @override
  String get enableLyricsForSong => 'Enable subtitles for this song';
  @override
  String get disableLyricsForSong => 'Disable subtitles for this song';
  @override
  String get lyricsEnabledSnackbar => 'Subtitles enabled for this song';
  @override
  String get lyricsDisabledSnackbar => 'Saved: subtitles disabled for this song';
  @override
  String get searchKaraokeDatabase => 'Search karaoke in database';
  @override
  String get manageLyricsVersionsTooltip => 'Manage lyrics versions';
  @override
  String get lyricsVersionsSheetTitle => 'Lyrics & Karaoke Versions';
  @override
  String get lyricsVersionsButton => 'Versions';
  @override
  String get lyricsDisabledOptionTitle => 'No Subtitles (Disabled)';
  @override
  String get lyricsDisabledOptionSubtitle => 'Hide lyrics for this track';
  @override
  String get syncedLyricsSubtitle => 'Synced lyrics along with music';
  @override
  String get staticLyricsSubtitle => 'Plain static song lyrics';
  @override
  String get karaokeBadge => '⏱️ Karaoke';
  @override
  String get staticTextBadge => '📄 Text';
  @override
  String get searchAnotherKaraoke => 'Search another karaoke online';
  @override
  String deleteLyricsVersionDialogTitle(String key) => 'Delete "$key"?';
  @override
  String get deleteLyricsVersionButton => 'Delete version';
  @override
  String resetKaraokeDialogTitle(String title) => 'Reset versions for "$title"?';
  @override
  String get resetKaraokeButton => 'Reset karaoke';
  @override
  String get searchLyricsPromptTitle => 'Search Lyrics & Karaoke';
  @override
  String get searchLyricsHint => 'Artist or song title...';
  @override
  String get searchButtonShort => 'Search';
  @override
  String searchAllCount(int count) => 'All ($count)';
  @override
  String searchKaraokeCount(int count) => '⏱️ Karaoke ($count)';
  @override
  String searchTextCount(int count) => '📄 Text ($count)';
  @override
  String get searchingLrclib => 'Searching karaoke in LRCLIB database...';
  @override
  String get lrclibEmpty => 'Nothing found. Try modifying your query.';
  @override
  String get lrclibSearchError => 'Search failed. Please check your network.';
  @override
  String lrclibSavedSnackbar(String artist, String title) => 'Saved karaoke from LRCLIB: $artist - $title';
  @override
  String get previewLyrics => 'Preview';
  @override
  String get selectLyrics => 'Select';
  @override
  String get backAction => 'Back';
  @override
  String get saveKaraokeAction => 'Save this karaoke';
  @override
  String get saveTextAction => 'Save this text';
  @override
  String lyricsSourceLrclib(String id) => 'Source: LRCLIB (#$id)';
  @override
  String formatLyricsTrackKey(String key) {
    if (key == 'Вбудований текст') return 'Embedded lyrics';
    if (key.startsWith('YouTube (авто)')) return 'YouTube (auto)';
    if (key.startsWith('Караоке [LRCLIB]')) return key.replaceFirst('Караоке', 'Karaoke');
    if (key.startsWith('Текст [LRCLIB]')) return key.replaceFirst('Текст', 'Lyrics');
    if (key.startsWith('Текст (Lyrics.ovh)')) return 'Lyrics (Lyrics.ovh)';
    if (key.startsWith('Караоке (LRCLIB)')) return 'Karaoke (LRCLIB)';
    return key;
  }
  @override
  String get lyricsLoadError => 'Failed to load lyrics.';
}
