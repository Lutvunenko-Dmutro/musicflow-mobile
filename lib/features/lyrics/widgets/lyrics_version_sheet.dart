import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio/lyrics_manager_mixin.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_version_card.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class LyricsVersionSheet extends StatelessWidget {
  final AudioProvider audioProvider;
  final SongModel? song;

  const LyricsVersionSheet({super.key, required this.audioProvider, required this.song});

  static Future<void> show(BuildContext context, {required AudioProvider audioProvider, required SongModel? song}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => LyricsVersionSheet(audioProvider: audioProvider, song: song),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String msg, Color btnColor) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF222222),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            content: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel, style: const TextStyle(color: Colors.white60))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white),
                child: Text(context.l10n.save),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final available = audioProvider.availableLyrics ?? {};
    final isDisabled = audioProvider.isLyricsDisabledForCurrentSong;
    final selectedKey = audioProvider.selectedLyricsKey;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.subtitles_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.lyricsVersionsSheetTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(song?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LyricsVersionCard(
              isSelected: isDisabled,
              icon: Icons.subtitles_off_rounded,
              iconColor: Colors.amber,
              title: context.l10n.lyricsDisabledOptionTitle,
              subtitle: context.l10n.lyricsDisabledOptionSubtitle,
              badge: null,
              onTap: () {
                audioProvider.changeLyricsTrack(LyricsManagerMixin.disabledLyricsKey, songId: song?.id);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  children: available.keys.map((key) {
                    final isSel = !isDisabled && key == selectedKey;
                    final isKaraoke = key.contains('Караоке') || (available[key] != null && RegExp(r'\[\d+:\d+').hasMatch(available[key]!));
                    return Padding(
                       padding: const EdgeInsets.only(bottom: 8),
                      child: LyricsVersionCard(
                        isSelected: isSel,
                        icon: key.toLowerCase().contains('youtube') ? Icons.play_circle_fill_rounded : Icons.mic_external_on_rounded,
                        iconColor: AppColors.primary,
                        title: context.l10n.formatLyricsTrackKey(key),
                        subtitle: isKaraoke ? context.l10n.syncedLyricsSubtitle : context.l10n.staticLyricsSubtitle,
                        badge: isKaraoke ? context.l10n.karaokeBadge : context.l10n.staticTextBadge,
                        onTap: () {
                          audioProvider.changeLyricsTrack(key, songId: song?.id);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (song != null) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  LyricsSearchSheet.show(context, song: song!);
                },
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(context.l10n.searchAnotherKaraoke),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (selectedKey != null && !isDisabled)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final ok = await _confirm(context, context.l10n.deleteLyricsVersionButton, context.l10n.deleteLyricsVersionDialogTitle(selectedKey), Colors.redAccent);
                          if (ok && context.mounted) {
                            await audioProvider.removeLyricsTrack(song!, selectedKey);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                        label: Text(context.l10n.deleteLyricsVersionButton, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final ok = await _confirm(context, context.l10n.resetKaraokeButton, context.l10n.resetKaraokeDialogTitle(song!.title), Colors.amber);
                        if (ok && context.mounted) {
                          await audioProvider.resetAllLyricsForSong(song!);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.restore_rounded, size: 16, color: Colors.amber),
                      label: Text(context.l10n.resetKaraokeButton, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
