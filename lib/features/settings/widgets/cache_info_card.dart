import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/cache_item_row.dart';
import 'package:music_flow_mobile/features/settings/utils/cache_cleanup_helper.dart';

class CacheInfoCard extends StatefulWidget {
  const CacheInfoCard({super.key});

  @override
  State<CacheInfoCard> createState() => _CacheInfoCardState();
}

class _CacheInfoCardState extends State<CacheInfoCard> {
  CacheSizeData _data = CacheSizeData(
    tempBytes: 0,
    tempFilesCount: 0,
    lyricsBytes: 0,
    lyricsCount: 0,
    dbBytes: 0,
    historyCount: 0,
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final data = await CacheCleanupHelper.calculateSizes();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleClearTemp() async {
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: 'Очистити обкладинки?',
      message: 'Це видалить тимчасові файли обкладинок. Самі аудіофайли пісень залишаться недоторканими.',
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearTempFiles();
    await _calculateCacheSize();
    _showFeedback('✅ Тимчасові обкладинки та файли очищено!');
  }

  Future<void> _handleClearLyrics() async {
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: 'Очистити тексти пісень?',
      message: 'Це видалить закешовані тексти. Вони завантажаться заново при відкритті пісень з інтернету.',
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearLyricsCache();
    await _calculateCacheSize();
    _showFeedback('✅ Збережені тексти пісень очищено!');
  }

  Future<void> _handleClearDatabase() async {
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: 'Скинути індекс тегів?',
      message: 'Це очистить локальний кеш тегів. Плеєр просто пересканує файли при наступному вході в бібліотеку. Самі пісні не видаляються.',
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearDatabaseCache();
    await _calculateCacheSize();
    _showFeedback('✅ Кеш метаданих локальних пісень очищено!');
  }

  Future<void> _handleClearHistory() async {
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: 'Очистити історію?',
      message: 'Це видалить усі записи з вкладки "Історія". Самі завантажені пісні та кеш залишаться недоторканими.',
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearHistory();
    await _calculateCacheSize();
    _showFeedback('✅ Історію прослуховувань очищено!');
  }

  Future<void> _handleClearAll() async {
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: 'Очистити весь кеш?',
      message: 'Будуть очищені тимчасові файли обкладинок, збережені тексти пісень та індекс тегів. Всі завантажені пісні та історія залишаться на пристрої.',
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearAll();
    await _calculateCacheSize();
    _showFeedback('✅ Весь кеш успішно очищено!');
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
              const Text('Сховище та дані', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 20),
                tooltip: 'Оновити',
                onPressed: _calculateCacheSize,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Всього зайнято: ${CacheCleanupHelper.formatBytes(_data.totalBytes)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Divider(height: 24),
          CacheItemRow(
            icon: Icons.image_outlined,
            title: 'Обкладинки та файли',
            subtitle: '${_data.tempFilesCount} файлів у temp',
            sizeText: CacheCleanupHelper.formatBytes(_data.tempBytes),
            onClear: _handleClearTemp,
            clearTooltip: 'Видалити тільки тимчасові обкладинки',
            isZero: _data.tempBytes == 0,
          ),
          const SizedBox(height: 10),
          CacheItemRow(
            icon: Icons.lyrics_outlined,
            title: 'Тексти пісень (LRC)',
            subtitle: '${_data.lyricsCount} закешовано',
            sizeText: CacheCleanupHelper.formatBytes(_data.lyricsBytes),
            onClear: _handleClearLyrics,
            clearTooltip: 'Видалити тільки збережені тексти',
            isZero: _data.lyricsBytes == 0,
          ),
          const SizedBox(height: 10),
          CacheItemRow(
            icon: Icons.storage_outlined,
            title: 'Кеш тегів бази даних',
            subtitle: 'Індекс локальних пісень',
            sizeText: CacheCleanupHelper.formatBytes(_data.dbBytes),
            onClear: _handleClearDatabase,
            clearTooltip: 'Скинути індекс тегів пісень',
            isZero: _data.dbBytes == 0,
          ),
          const SizedBox(height: 10),
          CacheItemRow(
            icon: Icons.history,
            title: 'Історія прослуховувань',
            subtitle: '${_data.historyCount} треків у вкладці "Історія"',
            sizeText: '${_data.historyCount} шт.',
            onClear: _handleClearHistory,
            clearTooltip: 'Видалити тільки історію прослуховувань',
            isZero: _data.historyCount == 0,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
              label: const Text('Очистити весь тимчасовий кеш', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _data.totalBytes == 0 ? null : _handleClearAll,
            ),
          ),
        ],
      ),
    );
  }
}
