import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class CacheInfoCard extends StatefulWidget {
  const CacheInfoCard({super.key});

  @override
  State<CacheInfoCard> createState() => _CacheInfoCardState();
}

class _CacheInfoCardState extends State<CacheInfoCard> {
  int _tempBytes = 0;
  int _tempFilesCount = 0;
  int _lyricsBytes = 0;
  int _lyricsCount = 0;
  int _dbBytes = 0;
  bool _isLoading = false;

  int get _totalBytes => _tempBytes + _lyricsBytes + _dbBytes;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 Б';
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} МБ';
  }

  Future<void> _calculateCacheSize() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    int tempBytes = 0;
    int tempCount = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            tempBytes += entity.lengthSync();
            tempCount++;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Не вдалося вирахувати розмір temp: $e', 'SETTINGS');
    }

    int lyricsBytes = 0;
    int lyricsCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith('lyrics_cache_')) {
          lyricsCount++;
          final val = prefs.getString(key);
          if (val != null) {
            lyricsBytes += val.length;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Не вдалося вирахувати розмір lyrics: $e', 'SETTINGS');
    }

    int dbBytes = 0;
    try {
      dbBytes = await locator<DatabaseService>().getDatabaseSizeBytes();
    } catch (e) {
      AppLogger.warning('Не вдалося вирахувати розмір БД: $e', 'SETTINGS');
    }

    if (mounted) {
      setState(() {
        _tempBytes = tempBytes;
        _tempFilesCount = tempCount;
        _lyricsBytes = lyricsBytes;
        _lyricsCount = lyricsCount;
        _dbBytes = dbBytes;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith('lyrics_cache_')) {
          await prefs.remove(key);
        }
      }

      await _calculateCacheSize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Тимчасовий кеш успішно очищено!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Помилка очищення кешу: $e', e, null, 'SETTINGS');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Пам\'ять та кеш',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 20),
                tooltip: 'Оновити',
                onPressed: _calculateCacheSize,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Всього зайнято: ${_formatBytes(_totalBytes)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Divider(height: 24),
          _buildRow(
            icon: Icons.image_outlined,
            title: 'Обкладинки та тимчасові файли',
            subtitle: '$_tempFilesCount файлів у temp',
            sizeText: _formatBytes(_tempBytes),
          ),
          const SizedBox(height: 12),
          _buildRow(
            icon: Icons.lyrics_outlined,
            title: 'Кеш текстів пісень (LRC)',
            subtitle: '$_lyricsCount текстів збережено',
            sizeText: _formatBytes(_lyricsBytes),
          ),
          const SizedBox(height: 12),
          _buildRow(
            icon: Icons.storage_outlined,
            title: 'База даних (SQLite)',
            subtitle: 'Історія, збережені пресети',
            sizeText: _formatBytes(_dbBytes),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
              label: const Text(
                'Очистити тимчасовий кеш',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _clearCache,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String sizeText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Text(
          sizeText,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
