import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/history_model.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/core/widgets/song_download_button.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class HistoryListItem extends StatelessWidget {
  final HistoryModel item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const HistoryListItem({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
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
    final audioProvider = context.watch<AudioProvider>();
    final isCurrent = audioProvider.currentSong?.id == item.id;
    final isPlaying = isCurrent && audioProvider.isPlaying;
    final primary = Theme.of(context).primaryColor;

    Color tileColor = Colors.transparent;
    Border? border;

    if (isSelected) {
      tileColor = primary.withValues(alpha: 0.2);
      border = Border.all(color: primary.withValues(alpha: 0.5), width: 1);
    } else if (isCurrent) {
      tileColor = AppColors.activeSongHighlight;
      border = Border.all(color: primary.withValues(alpha: 0.35), width: 1);
    }

    final bool isDownloaded = _isDownloaded(item);
    final song = SongModel(
      id: item.id,
      title: item.title,
      author: item.author,
      duration: Duration(milliseconds: item.durationMs),
      coverUrl: item.coverUrl,
      coverBytes: item.coverBytes,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: SizedBox(
            width: 48,
            height: 48,
            child: SmartCover(
              song: song,
              size: 48,
              borderRadius: 8.0,
            ),
          ),
          title: Row(
            children: [
              if (isPlaying) ...[
                Icon(Icons.graphic_eq, size: 14, color: primary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isCurrent ? primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Icon(
                isDownloaded ? Icons.offline_pin : Icons.cloud_outlined,
                size: 13,
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
          trailing: _buildTrailing(context, isDownloaded, primary),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, bool isDownloaded, Color primary) {
    if (isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? primary : Colors.grey[600],
        size: 22,
      );
    }

    return Row(
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
            color: primary.withValues(alpha: 0.2),
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
    );
  }
}
