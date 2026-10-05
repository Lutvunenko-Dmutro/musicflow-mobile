import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class LibraryListItem extends StatelessWidget {
  final SongModel song;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LibraryListItem({
    super.key,
    required this.song,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final isCurrent = audioProvider.currentSong?.id == song.id;
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
                  song.title,
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
          subtitle: Text(
            song.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          trailing: _buildTrailing(primary),
          onLongPress: onLongPress,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildTrailing(Color primary) {
    if (isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? primary : Colors.grey[600],
        size: 22,
      );
    }

    if (!song.isLocal || song.localPath == null) return const SizedBox.shrink();
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
    } catch (_) {}

    if (extraDate.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(extraDate, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 2),
        Text(extraSize, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }
}
