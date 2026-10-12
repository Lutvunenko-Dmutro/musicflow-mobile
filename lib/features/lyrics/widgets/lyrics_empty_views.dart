import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class LyricsDisabledView extends StatelessWidget {
  final SongModel? song;
  final VoidCallback onEnable;

  const LyricsDisabledView({super.key, required this.song, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.subtitles_off_outlined, size: 54, color: Colors.white38),
          const SizedBox(height: 14),
          Text(l10n.lyricsDisabledForSong, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(l10n.lyricsSettingsSavedForTrack, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          if (song != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.subtitles, size: 18),
              label: Text(l10n.enableLyricsForSong),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LyricsEmptyView extends StatelessWidget {
  final SongModel? song;
  final String? errorMsg;

  const LyricsEmptyView({super.key, required this.song, this.errorMsg});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String displayText;
    if (errorMsg != null) {
      if (errorMsg!.contains('інтернет') || errorMsg!.contains('internet')) {
        displayText = l10n.noInternetConnection;
      } else {
        displayText = l10n.lyricsLoadError;
      }
    } else {
      displayText = l10n.lyricsNotFound;
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lyrics_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(displayText, style: const TextStyle(color: Colors.white54, fontSize: 15)),
          if (song != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => LyricsSearchSheet.show(context, song: song!),
              icon: const Icon(Icons.search, size: 16),
              label: Text(l10n.searchKaraokeDatabase),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                foregroundColor: Theme.of(context).primaryColor,
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
