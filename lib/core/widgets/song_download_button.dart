import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/download_service.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class SongDownloadButton extends StatelessWidget {
  final SongModel song;

  const SongDownloadButton({super.key, required this.song});

  String _formatSpeed(String speed, AppStrings l10n) {
    if (speed == "З'єднання..." || speed == "Connecting...") return l10n.connecting;
    if (speed == "Обчислення..." || speed == "Calculating...") return l10n.calculating;
    if (speed == "Помилка" || speed == "Error") return l10n.errorLabel;
    if (speed == "Вже завантажено" || speed == "Already downloaded") return l10n.alreadyDownloaded;
    return speed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<Map<String, DownloadInfo>>(
      valueListenable: locator<DownloadService>().downloadProgress,
      builder: (context, progressMap, child) {
        final info = progressMap[song.id];
        
        if (info != null) {
          final progress = info.progress;
          final speed = _formatSpeed(info.speedText, l10n);

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
    final l10n = context.l10n;
    final confirmDownload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.download),
        content: Text(l10n.downloadSongPrompt(song.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.download, style: const TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );

    if (confirmDownload != true) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.downloadStarted(song.title)),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    locator<DownloadService>().downloadSong(
      song,
      onFileExists: () async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.fileAlreadyExists),
            content: Text(l10n.fileAlreadyExistsPrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.overwrite, style: const TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ?? false;
      },
    );
  }
}
