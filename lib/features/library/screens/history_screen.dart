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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Історія'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Ви ще нічого не слухали'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await locator<DatabaseService>().removeFromHistory(item.id);
                      },
                      child: HistoryListItem(
                        item: item,
                        onTap: () => _playSong(item, index),
                      ),
                    );
                  },
                ),
    );
  }
}
