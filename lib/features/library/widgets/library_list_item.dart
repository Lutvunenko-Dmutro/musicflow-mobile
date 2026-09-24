import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
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
    return ListTile(
      leading: SizedBox(
        width: 50,
        height: 50,
        child: SmartCover(
          song: song,
          size: 50,
          borderRadius: 8.0,
        ),
      ),
      title: Text(song.title, maxLines: 1),
      subtitle: Text(song.author, maxLines: 1),
      trailing: _buildTrailing(),
      selected: isSelected,
      selectedTileColor: Colors.redAccent.withValues(alpha: 0.2),
      onLongPress: onLongPress,
      onTap: onTap,
    );
  }

  Widget _buildTrailing() {
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
    } catch (e) {
      // Ignore missing file for UI metadata, but we can print for debug
      // AppLogger.warning('Failed to load file stats: $e', 'LIBRARY_ITEM'); 
    }
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
