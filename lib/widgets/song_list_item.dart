import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../services/download_service.dart';

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
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: song.coverBytes != null
                ? Image.memory(
                    song.coverBytes!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset('assets/icon.png', width: 48, height: 48, fit: BoxFit.cover),
                  )
                : (song.coverUrl.isEmpty
                    ? Image.asset('assets/icon.png', width: 48, height: 48, fit: BoxFit.cover)
                    : Image.network(
                        song.coverUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset('assets/icon.png', width: 48, height: 48, fit: BoxFit.cover),
                      )),
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
                  '${(song.duration.inSeconds / 1024 / 1024 * 5).toStringAsFixed(1)} MB', // Fake size for now based on duration
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
            onPressed: onPlay ?? onTap ?? () {
              context.read<AudioProvider>().playSong(song);
            },
          ),
          ValueListenableBuilder<Map<String, DownloadInfo>>(
            valueListenable: DownloadService.instance.downloadProgress,
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
                onPressed: () {
                  DownloadService.instance.downloadSong(
                    song,
                    onFileExists: () async {
                      final result = await showDialog<bool>(
                        context: context,
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
                      );
                      return result ?? false;
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Завантаження: ${song.title}'),
                      backgroundColor: const Color(0xFF212121),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
