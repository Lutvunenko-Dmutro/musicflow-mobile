import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpdateDialog(info: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  File? _downloadedFile;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Завантаження оновлення...';
    });

    try {
      final file = await UpdateService.instance.downloadApk(
        widget.info,
        onProgress: (p, received, total) {
          if (mounted) {
            setState(() {
              _progress = p;
              final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
              final totMb = total > 0 ? (total / (1024 * 1024)).toStringAsFixed(1) : '?';
              _statusText = '$recMb MB / $totMb MB (${(p * 100).toInt()}%)';
            });
          }
        },
      );

      _downloadedFile = file;
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Завантаження завершено! Встановлення...';
        });
        await UpdateService.instance.installApk(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Помилка завантаження: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final sizeMb = widget.info.fileSizeBytes > 0
        ? ' • ${(widget.info.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.system_update_rounded, color: primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Нове оновлення! 🎉', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Версія v${widget.info.version}$sizeMb', style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Що нового:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: SingleChildScrollView(
              child: Text(widget.info.changelog, style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white)),
            ),
          ),
          if (_isDownloading || _statusText.isNotEmpty) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: _isDownloading ? _progress : null, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(primary)),
            const SizedBox(height: 6),
            Text(_statusText, style: TextStyle(fontSize: 11, color: _isDownloading ? primary : Colors.white70)),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Пізніше', style: TextStyle(color: Colors.white54)),
          ),
        ElevatedButton(
          onPressed: _isDownloading ? null : (_downloadedFile != null ? () => UpdateService.instance.installApk(_downloadedFile!) : _startDownload),
          style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
          child: Text(_downloadedFile != null ? 'Встановити' : (_isDownloading ? 'Завантаження...' : 'Оновити зараз')),
        ),
      ],
    );
  }
}
