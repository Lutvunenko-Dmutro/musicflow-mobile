import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import 'song_download_button.dart';
import 'smart_cover.dart';

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
          IconButton(
            icon: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
            onPressed: onPlay ?? onTap ?? () {
              context.read<AudioProvider>().playSong(song);
            },
          ),
          SongDownloadButton(song: song),
        ],
      ),
    );
  }
}
