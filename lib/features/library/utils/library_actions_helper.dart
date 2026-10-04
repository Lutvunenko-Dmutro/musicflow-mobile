import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/locator.dart';

class LibraryActionsHelper {
  static Future<bool> confirmDeleteDialog(BuildContext context, int count) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити пісні?'),
        content: Text('Ви впевнені, що хочете видалити $count пісень?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Видалити', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  static Future<void> deleteSongs({
    required AudioProvider audioProvider,
    required List<String> idsToDelete,
    required List<SongModel> songs,
  }) async {
    final libProvider = locator<LocalLibraryProvider>();

    for (final id in idsToDelete) {
      if (audioProvider.currentSong?.id == id) {
        await audioProvider.stop();
      }

      final song = songs.firstWhere((s) => s.id == id, orElse: () => songs.first);
      if (song.id == id && song.localPath != null) {
        final file = File(song.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      libProvider.removeSong(id);
    }
  }
}
