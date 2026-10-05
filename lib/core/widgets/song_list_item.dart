import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/core/widgets/song_download_button.dart';
import 'package:music_flow_mobile/core/animations/scale_tap_button.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class SongListItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  const SongListItem({super.key, required this.song, this.onTap, this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        final isThisSong = audio.currentSong?.id == song.id;
        final isThisPlaying = isThisSong && audio.isPlaying;
        final primary = Theme.of(context).primaryColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isThisSong ? AppColors.activeSongHighlight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isThisSong
                ? Border.all(color: primary.withValues(alpha: 0.35), width: 1)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                SmartCover(
                  song: song,
                  size: 48,
                  borderRadius: 8.0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isThisPlaying) ...[
                            Icon(Icons.graphic_eq, size: 14, color: primary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isThisSong ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                                color: isThisSong ? primary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (song.isLocal && song.localPath != null)
                  Builder(
                    builder: (context) {
                      String extraSize = "";
                      try {
                        final file = File(song.localPath!);
                        if (file.existsSync()) {
                          extraSize = "${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB";
                        }
                      } catch (_) {}
                      if (extraSize.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(extraSize, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      );
                    },
                  ),
                if (isThisSong && audio.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  ScaleTapButton(
                    onTap: () {
                      if (isThisSong) {
                        isThisPlaying ? audio.pause() : audio.resume();
                      } else {
                        if (onPlay != null) {
                          onPlay!();
                        } else if (onTap != null) {
                          onTap!();
                        } else {
                          audio.playSong(song);
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: isThisSong ? primary : Colors.white70,
                        size: 32,
                      ),
                    ),
                  ),
                SongDownloadButton(song: song),
              ],
            ),
          ),
        );
      },
    );
  }
}
