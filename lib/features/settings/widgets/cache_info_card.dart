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
  int _historyCount = 0;
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
    int historyCount = 0;
    try {
      final dbService = locator<DatabaseService>();
      dbBytes = await dbService.getDatabaseSizeBytes();
      historyCount = await dbService.getHistoryCount();
    } catch (e) {
      AppLogger.warning('Не вдалося вирахувати розмір БД/історії: $e', 'SETTINGS');
    }

    if (mounted) {
      setState(() {
        _tempBytes = tempBytes;
        _tempFilesCount = tempCount;
        _lyricsBytes = lyricsBytes;
        _lyricsCount = lyricsCount;
        _dbBytes = dbBytes;
        _historyCount = historyCount;
        _isLoading = false;
      });
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Очистити', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _clearTempFiles() async {
    final confirmed = await _confirmAction(
      title: 'Очистити обкладинки?',
      message: 'Це видалить тимчасові файли обкладинок. Самі аудіофайли пісень залишаться недоторканими.',
    );
    if (!confirmed) return;

    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
      await _calculateCacheSize();
      _showFeedback('✅ Тимчасові обкладинки та файли очищено!');
    } catch (e) {
      AppLogger.error('Помилка очищення temp: $e', e, null, 'SETTINGS');
    }
  }

  Future<void> _clearLyricsCache() async {
    final confirmed = await _confirmAction(
      title: 'Очистити тексти пісень?',
      message: 'Це видалить закешовані тексти. Вони завантажаться заново при відкритті пісень з інтернету.',
    );
    if (!confirmed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith('lyrics_cache_')) {
          await prefs.remove(key);
        }
      }
      await _calculateCacheSize();
      _showFeedback('✅ Збережені тексти пісень очищено!');
    } catch (e) {
      AppLogger.error('Помилка очищення lyrics: $e', e, null, 'SETTINGS');
    }
  }

  Future<void> _clearDatabaseCache() async {
    final confirmed = await _confirmAction(
      title: 'Скинути індекс тегів?',
      message: 'Це очистить локальний кеш тегів. Плеєр просто пересканує файли при наступному вході в бібліотеку. Самі пісні не видаляються.',
    );
    if (!confirmed) return;

    try {
      final db = await locator<DatabaseService>().database;
      await db.delete('local_songs_cache');
      await _calculateCacheSize();
      _showFeedback('✅ Кеш метаданих локальних пісень очищено!');
    } catch (e) {
      AppLogger.error('Помилка очищення DB кешу: $e', e, null, 'SETTINGS');
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await _confirmAction(
      title: 'Очистити історію?',
      message: 'Це видалить усі записи з вкладки "Історія". Самі завантажені пісні та кеш залишаться недоторканими.',
    );
    if (!confirmed) return;

    try {
      await locator<DatabaseService>().clearHistory();
      await _calculateCacheSize();
      _showFeedback('✅ Історію прослуховувань очищено!');
    } catch (e) {
      AppLogger.error('Помилка очищення історії: $e', e, null, 'SETTINGS');
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirmAction(
      title: 'Очистити весь кеш?',
      message: 'Будуть очищені тимчасові файли обкладинок, збережені тексти пісень та індекс тегів. Всі завантажені пісні та історія залишаться на пристрої.',
    );
    if (!confirmed) return;

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

      final db = await locator<DatabaseService>().database;
      await db.delete('local_songs_cache');

      await _calculateCacheSize();
      _showFeedback('✅ Весь кеш успішно очищено!');
    } catch (e) {
      AppLogger.error('Помилка повного очищення кешу: $e', e, null, 'SETTINGS');
    }
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                'Сховище та дані',
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
            title: 'Обкладинки та файли',
            subtitle: '$_tempFilesCount файлів у temp',
            sizeText: _formatBytes(_tempBytes),
            onClear: _clearTempFiles,
            clearTooltip: 'Видалити тільки тимчасові обкладинки',
            isZero: _tempBytes == 0,
          ),
          const SizedBox(height: 10),
          _buildRow(
            icon: Icons.lyrics_outlined,
            title: 'Тексти пісень (LRC)',
            subtitle: '$_lyricsCount закешовано',
            sizeText: _formatBytes(_lyricsBytes),
            onClear: _clearLyricsCache,
            clearTooltip: 'Видалити тільки збережені тексти',
            isZero: _lyricsBytes == 0,
          ),
          const SizedBox(height: 10),
          _buildRow(
            icon: Icons.storage_outlined,
            title: 'Кеш тегів бази даних',
            subtitle: 'Індекс локальних пісень',
            sizeText: _formatBytes(_dbBytes),
            onClear: _clearDatabaseCache,
            clearTooltip: 'Скинути індекс тегів пісень',
            isZero: _dbBytes == 0,
          ),
          const SizedBox(height: 10),
          _buildRow(
            icon: Icons.history,
            title: 'Історія прослуховувань',
            subtitle: '$_historyCount треків у вкладці "Історія"',
            sizeText: '$_historyCount шт.',
            onClear: _clearHistory,
            clearTooltip: 'Видалити тільки історію прослуховувань',
            isZero: _historyCount == 0,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
              label: const Text(
                'Очистити весь тимчасовий кеш',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _totalBytes == 0 ? null : _clearAll,
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
    required VoidCallback onClear,
    required String clearTooltip,
    required bool isZero,
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
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 20,
            color: isZero ? Colors.grey.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.8),
          ),
          tooltip: clearTooltip,
          onPressed: isZero ? null : onClear,
        ),
      ],
    );
  }
}
