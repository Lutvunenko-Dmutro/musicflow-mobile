import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/history_model.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/core/widgets/song_download_button.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class HistoryListItem extends StatelessWidget {
  final HistoryModel item;
  final VoidCallback onTap;

  const HistoryListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  bool _isDownloaded(HistoryModel item) {
    if (item.id.startsWith('/')) {
      return File(item.id).existsSync();
    }
    final libProvider = locator<LocalLibraryProvider>();
    for (var song in libProvider.songs) {
      if (song.localPath != null &&
          (song.localPath!.contains(item.id) || song.title == item.title)) {
        return true;
      }
    }
    return false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} дн. тому';
    if (diff.inHours > 0) return '${diff.inHours} год. тому';
    if (diff.inMinutes > 0) return '${diff.inMinutes} хв. тому';
    return 'Щойно';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDownloaded = _isDownloaded(item);
    final song = SongModel(
      id: item.id,
      title: item.title,
      author: item.author,
      duration: Duration(milliseconds: item.durationMs),
      coverUrl: item.coverUrl,
      coverBytes: item.coverBytes,
    );

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SmartCover(
          song: song,
          size: 50,
          borderRadius: 8.0,
        ),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Icon(
            isDownloaded ? Icons.offline_pin : Icons.cloud_outlined,
            size: 14,
            color: isDownloaded ? Colors.greenAccent : Colors.grey,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${item.author} • ${_formatDate(item.lastPlayedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDownloaded && !item.id.startsWith('/'))
            SongDownloadButton(
              song: SongModel(
                id: item.id,
                title: item.title,
                author: item.author,
                coverUrl: item.coverUrl,
                duration: Duration(milliseconds: item.durationMs),
                isLocal: false,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  '${item.playCount}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
