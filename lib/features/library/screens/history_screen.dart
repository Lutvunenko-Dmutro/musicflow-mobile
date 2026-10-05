import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/history_model.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/features/library/widgets/history_list_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryModel> _history = [];
  bool _isLoading = true;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
    locator<DatabaseService>().addListener(_loadHistory);
  }

  @override
  void dispose() {
    locator<DatabaseService>().removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await locator<DatabaseService>().getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  void _playSong(HistoryModel historyItem, int index) {
    final audioProvider = context.read<AudioProvider>();
    final songsToPlay = _history.map((h) {
      return SongModel(
        id: h.id,
        title: h.title,
        author: h.author,
        coverUrl: h.coverUrl,
        duration: Duration(milliseconds: h.durationMs),
        isLocal: h.id.startsWith('/'),
        localPath: h.id.startsWith('/') ? h.id : null,
        coverBytes: h.coverBytes,
      );
    }).toList();

    audioProvider.setQueue(songsToPlay, initialIndex: index);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Видалити з історії', style: TextStyle(color: Colors.white)),
        content: Text(
          'Видалити $count ${count == 1 ? 'трек' : 'треків'} з історії?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = locator<DatabaseService>();
      for (final id in _selectedIds.toList()) {
        await db.removeFromHistory(id);
      }
      if (mounted) setState(() => _selectedIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? 'Вибрано: ${_selectedIds.length}' : 'Історія'),
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedIds.clear()))
            : null,
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: Icon(_selectedIds.length == _history.length ? Icons.deselect : Icons.select_all),
              tooltip: _selectedIds.length == _history.length ? 'Зняти все' : 'Вибрати все',
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == _history.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(_history.map((h) => h.id));
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Видалити вибране',
              onPressed: _confirmDeleteSelected,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Ви ще нічого не слухали'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final isSelected = _selectedIds.contains(item.id);

                    final tile = HistoryListItem(
                      item: item,
                      isSelected: isSelected,
                      isSelectionMode: isSelectionMode,
                      onTap: () => isSelectionMode ? _toggleSelection(item.id) : _playSong(item, index),
                      onLongPress: () => _toggleSelection(item.id),
                    );

                    if (isSelectionMode) return tile;

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async => locator<DatabaseService>().removeFromHistory(item.id),
                      child: tile,
                    );
                  },
                ),
    );
  }
}
