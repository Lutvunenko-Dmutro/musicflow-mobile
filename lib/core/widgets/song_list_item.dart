import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/core/widgets/song_download_button.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class SongListItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  const SongListItem({super.key, required this.song, this.onTap, this.onPlay});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          SmartCover(
            song: song,
            size: 48,
            borderRadius: 6.0,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
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
                String extraDate = "";
                String extraSize = "";
                try {
                  final file = File(song.localPath!);
                  if (file.existsSync()) {
                    final date = file.lastModifiedSync();
                    final size = file.lengthSync();
                    extraDate = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
                    extraSize = "${(size / (1024 * 1024)).toStringAsFixed(1)} MB";
                  }
                } catch (e) {
                  // Ignored for UI metadata display
                }
                
                if (extraDate.isEmpty) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(extraDate, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(extraSize, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          Consumer<AudioProvider>(
            builder: (context, audio, child) {
              final isThisSong = audio.currentSong?.id == song.id;
              if (isThisSong && audio.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }
              final isThisPlaying = isThisSong && audio.isPlaying;
              return IconButton(
                icon: Icon(
                  isThisPlaying ? Icons.pause : Icons.play_arrow,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  if (isThisSong) {
                    if (isThisPlaying) {
                      audio.pause();
                    } else {
                      audio.resume();
                    }
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
              );
            },
          ),
          SongDownloadButton(song: song),
        ],
      ),
    );
  }
}
