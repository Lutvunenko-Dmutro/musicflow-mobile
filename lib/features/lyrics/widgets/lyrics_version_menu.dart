import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_version_sheet.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class LyricsVersionMenu extends StatelessWidget {
  final AudioProvider audioProvider;
  final SongModel? song;

  const LyricsVersionMenu({
    super.key,
    required this.audioProvider,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final available = audioProvider.availableLyrics;
    if (available == null || available.isEmpty) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.tune_rounded),
      tooltip: context.l10n.manageLyricsVersionsTooltip,
      onPressed: () => LyricsVersionSheet.show(
        context,
        audioProvider: audioProvider,
        song: song,
      ),
    );
  }
}
