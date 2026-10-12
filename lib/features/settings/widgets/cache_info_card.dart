import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/cache_item_row.dart';
import 'package:music_flow_mobile/features/settings/utils/cache_cleanup_helper.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

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
    if (mounted) setState(() { _data = data; _isLoading = false; });
  }

  Future<void> _handleClearTemp() async {
    final l10n = context.l10n;
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: l10n.clearTempDialogTitle,
      message: l10n.clearTempDialogMsg,
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearTempFiles();
    await _calculateCacheSize();
    _showFeedback(l10n.clearTempSuccess);
  }

  Future<void> _handleClearLyrics() async {
    final l10n = context.l10n;
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: l10n.clearLyricsDialogTitle,
      message: l10n.clearLyricsDialogMsg,
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearLyricsCache();
    await _calculateCacheSize();
    _showFeedback(l10n.clearLyricsSuccess);
  }

  Future<void> _handleClearDatabase() async {
    final l10n = context.l10n;
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: l10n.clearDbDialogTitle,
      message: l10n.clearDbDialogMsg,
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearDatabaseCache();
    await _calculateCacheSize();
    _showFeedback(l10n.clearDbSuccess);
  }

  Future<void> _handleClearHistory() async {
    final l10n = context.l10n;
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: l10n.clearHistoryDialogTitle,
      message: l10n.clearHistoryDialogMsg,
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearHistory();
    await _calculateCacheSize();
    _showFeedback(l10n.clearHistorySuccess);
  }

  Future<void> _handleClearAll() async {
    final l10n = context.l10n;
    final confirmed = await CacheCleanupHelper.confirmAction(
      context: context,
      title: l10n.clearAllDialogTitle,
      message: l10n.clearAllDialogMsg,
    );
    if (!confirmed) return;
    await CacheCleanupHelper.clearAll();
    await _calculateCacheSize();
    _showFeedback(l10n.clearAllSuccess);
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).primaryColor;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.storageAndDataTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 20),
                tooltip: l10n.refreshTooltip,
                onPressed: _calculateCacheSize,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.totalOccupied(CacheCleanupHelper.formatBytes(_data.totalBytes, context)),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
          ),
          const Divider(height: 24),
          CacheItemRow(
            icon: Icons.image_outlined,
            title: l10n.tempCoversTitle,
            subtitle: l10n.tempCoversSubtitle(_data.tempFilesCount),
            sizeText: CacheCleanupHelper.formatBytes(_data.tempBytes, context),
            onClear: _handleClearTemp,
            clearTooltip: l10n.clearTempTooltip,
            isZero: _data.tempBytes == 0,
          ),
          const SizedBox(height: 10),
          CacheItemRow(
            icon: Icons.lyrics_outlined,
            title: l10n.lyricsCacheTitle,
            subtitle: l10n.lyricsCacheSubtitle(_data.lyricsCount),
            sizeText: CacheCleanupHelper.formatBytes(_data.lyricsBytes, context),
            onClear: _handleClearLyrics,
            clearTooltip: l10n.clearLyricsTooltip,
            isZero: _data.lyricsBytes == 0,
          ),
          const SizedBox(height: 10),
          CacheItemRow(
            icon: Icons.storage_outlined,
            title: l10n.dbTagsTitle,
            subtitle: l10n.dbTagsSubtitle,
            sizeText: CacheCleanupHelper.formatBytes(_data.dbBytes, context),
            onClear: _handleClearDatabase,
            clearTooltip: l10n.clearDbTooltip,
            isZero: _data.dbBytes == 0,
          ),
          const SizedBox(height: 10),
          CacheItemRow(
            icon: Icons.history,
            title: l10n.historyCacheTitle,
            subtitle: l10n.historyCacheSubtitle(_data.historyCount),
            sizeText: l10n.historyItemsCount(_data.historyCount),
            onClear: _handleClearHistory,
            clearTooltip: l10n.clearHistoryTooltip,
            isZero: _data.historyCount == 0,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
              label: Text(l10n.clearAllTempCache, style: const TextStyle(color: Colors.redAccent)),
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
