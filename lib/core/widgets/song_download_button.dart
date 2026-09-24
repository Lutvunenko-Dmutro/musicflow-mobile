import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/download_service.dart';
import 'package:music_flow_mobile/locator.dart';

class SongDownloadButton extends StatelessWidget {
  final SongModel song;

  const SongDownloadButton({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, DownloadInfo>>(
      valueListenable: locator<DownloadService>().downloadProgress,
      builder: (context, progressMap, child) {
        final info = progressMap[song.id];
        
        if (info != null) {
          final progress = info.progress;
          final speed = info.speedText;

          if (progress < 0) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.error, color: Colors.red),
            );
          }
          
          if (progress >= 1.0) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            );
          }

          // Show progress with text
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      speed,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 3,
                    backgroundColor: Colors.white12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Not downloading, show download icon
        return IconButton(
          icon: const Icon(Icons.download, color: Colors.white70),
          onPressed: () => _startDownload(context),
        );
      },
    );
  }

  void _startDownload(BuildContext context) async {
    // 1. Ask for general download confirmation
    final confirmDownload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завантаження'),
        content: Text('Завантажити пісню "${song.title}" на пристрій?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Завантажити', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );

    if (confirmDownload != true) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Завантаження: ${song.title}'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    locator<DownloadService>().downloadSong(
      song,
      onFileExists: () async {
        // If we get here, it means the file already exists on the disk
        return await showDialog<bool>(
          context: context, // Note: Make sure context is still valid, or handle accordingly
          builder: (ctx) => AlertDialog(
            title: const Text('Файл вже існує'),
            content: const Text('Ця пісня вже завантажена. Бажаєте завантажити її знову (перезаписати)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Перезаписати', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ?? false;
      },
    );
  }
}
