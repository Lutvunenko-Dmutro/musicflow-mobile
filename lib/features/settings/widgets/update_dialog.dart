import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
      _statusText = 'Підготовка...';
    });
    try {
      final file = await UpdateService.instance.downloadApk(widget.info, onProgress: (p, rec, tot) {
        if (!mounted) return;
        setState(() {
          _progress = p;
          final recMb = (rec / 1048576).toStringAsFixed(1);
          final totMb = tot > 0 ? (tot / 1048576).toStringAsFixed(1) : '?';
          _statusText = '$recMb MB з $totMb MB (${(p * 100).toInt()}%)';
        });
      });
      _downloadedFile = file;
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Готово! Відкриваємо інсталятор...';
        });
        await UpdateService.instance.installApk(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Помилка: $e';
        });
      }
    }
  }

  List<String> _parseChangelog(String text) => text
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final sizeMb = widget.info.fileSizeBytes > 0 ? '${(widget.info.fileSizeBytes / 1048576).toStringAsFixed(1)} MB' : 'Новий APK';
    final items = _parseChangelog(widget.info.changelog);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primary, primary.withValues(alpha: 0.6)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Нове оновлення!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text('v${widget.info.version}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary)),
                          ),
                          const SizedBox(width: 8),
                          Text(sizeMb, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Що нового в цій версії:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item, style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.white))),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            if (_isDownloading || _statusText.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(minHeight: 7, value: _isDownloading ? _progress : null, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(primary)),
              ),
              const SizedBox(height: 5),
              Text(_statusText, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: _isDownloading ? primary : Colors.white70, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : (_downloadedFile != null ? () => UpdateService.instance.installApk(_downloadedFile!) : _startDownload),
              icon: Icon(_downloadedFile != null ? Icons.install_mobile_rounded : Icons.download_rounded, size: 20),
              label: Text(_downloadedFile != null ? 'Встановити зараз' : (_isDownloading ? 'Завантаження...' : 'Завантажити та оновити'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            ),
            if (!_isDownloading)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Нагадати пізніше', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
