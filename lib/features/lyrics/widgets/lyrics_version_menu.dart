import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio/lyrics_manager_mixin.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

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
    if (available == null || available.isEmpty) {
      return const SizedBox.shrink();
    }

    final primary = Theme.of(context).primaryColor;
    final isDisabled = audioProvider.isLyricsDisabledForCurrentSong;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate),
      tooltip: 'Вибрати версію або вимкнути',
      onSelected: (key) {
        audioProvider.changeLyricsTrack(key, songId: song?.id);
        final msg = key == LyricsManagerMixin.disabledLyricsKey
            ? 'Збережено: субтитри вимкнено для цієї пісні'
            : 'Вибрано: $key';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
        );
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        items.add(
          PopupMenuItem<String>(
            value: LyricsManagerMixin.disabledLyricsKey,
            child: Row(
              children: [
                Icon(
                  isDisabled ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 18,
                  color: isDisabled ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Без субтитрів (Вимкнено)', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        items.addAll(
          available.keys.map((key) {
            final isSelected = !isDisabled && key == audioProvider.selectedLyricsKey;
            return PopupMenuItem<String>(
              value: key,
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 18,
                    color: isSelected ? primary : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      key,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? primary : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          }),
        );

        return items;
      },
    );
  }
}
