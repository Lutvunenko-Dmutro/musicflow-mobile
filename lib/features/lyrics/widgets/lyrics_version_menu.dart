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

  IconData _getSourceIcon(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('youtube')) return Icons.play_circle_filled_rounded;
    if (lower.contains('lrclib')) return Icons.mic_external_on_rounded;
    if (lower.contains('ovh')) return Icons.language_rounded;
    return Icons.lyrics_rounded;
  }

  Color _getSourceColor(String key, Color primary) {
    final lower = key.toLowerCase();
    if (lower.contains('youtube')) return Colors.redAccent;
    if (lower.contains('lrclib')) return primary;
    if (lower.contains('ovh')) return Colors.lightBlueAccent;
    return primary;
  }

  Future<bool> _confirm(BuildContext context, String title, String msg, Color btnColor) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF222222),
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            content: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати', style: TextStyle(color: Colors.white60))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white),
                child: const Text('Підтвердити'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleAction(BuildContext context, String key) async {
    if (key == '__reset_all__') {
      if (song == null) return;
      final ok = await _confirm(context, 'Скинути караоке?', 'Скинути всі версії для "${song!.title}" та завантажити заново?', Colors.amber);
      if (ok && context.mounted) {
        await audioProvider.resetAllLyricsForSong(song!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Караоке скинуто до початкового'), behavior: SnackBarBehavior.floating));
        }
      }
      return;
    }

    if (key == '__delete_selected__') {
      final selectedKey = audioProvider.selectedLyricsKey;
      if (song == null || selectedKey == null) return;
      final ok = await _confirm(context, 'Видалити поточну версію?', 'Видалити "$selectedKey" для "${song!.title}"?', Colors.redAccent);
      if (ok && context.mounted) {
        await audioProvider.removeLyricsTrack(song!, selectedKey);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Версію успішно видалено'), behavior: SnackBarBehavior.floating));
        }
      }
      return;
    }

    audioProvider.changeLyricsTrack(key, songId: song?.id);
    final msg = key == LyricsManagerMixin.disabledLyricsKey ? 'Збережено: субтитри вимкнено для цієї пісні' : 'Вибрано: $key';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final available = audioProvider.availableLyrics;
    if (available == null || available.isEmpty) return const SizedBox.shrink();

    final primary = Theme.of(context).primaryColor;
    final isDisabled = audioProvider.isLyricsDisabledForCurrentSong;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate),
      tooltip: 'Вибрати версію тексту або вимкнути',
      onSelected: (key) => _handleAction(context, key),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        items.add(
          PopupMenuItem<String>(
            value: LyricsManagerMixin.disabledLyricsKey,
            child: Row(
              children: [
                Icon(isDisabled ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: isDisabled ? Colors.amber : Colors.grey),
                const SizedBox(width: 8),
                const Icon(Icons.subtitles_off_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                const Expanded(child: Text('Без субтитрів (Вимкнено)', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        items.addAll(
          available.keys.map((key) {
            final isSelected = !isDisabled && key == audioProvider.selectedLyricsKey;
            final isKaraoke = key.contains('Караоке') || (available[key] != null && RegExp(r'\[\d+:\d+').hasMatch(available[key]!));
            final icon = _getSourceIcon(key);
            final color = _getSourceColor(key, primary);

            return PopupMenuItem<String>(
              value: key,
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: isSelected ? primary : Colors.grey),
                  const SizedBox(width: 8),
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      key,
                      style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primary : null),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: (isKaraoke ? Colors.greenAccent : Colors.grey).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(isKaraoke ? '⏱️' : '📄', style: const TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            );
          }),
        );

        if (song != null) {
          items.add(const PopupMenuDivider());
          if (audioProvider.selectedLyricsKey != null && !isDisabled) {
            items.add(
              const PopupMenuItem<String>(
                value: '__delete_selected__',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Видалити поточну версію', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            );
          }
          items.add(
            const PopupMenuItem<String>(
              value: '__reset_all__',
              child: Row(
                children: [
                  Icon(Icons.restore_rounded, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Скинути караоке до початкового', style: TextStyle(color: Colors.amber, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}
