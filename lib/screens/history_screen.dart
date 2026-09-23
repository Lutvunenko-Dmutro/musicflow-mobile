import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_model.dart';
import '../services/database_service.dart';
import '../providers/audio_provider.dart';
import '../models/song_model.dart';
import '../providers/local_library_provider.dart';
import '../locator.dart';
import '../widgets/song_download_button.dart';
import '../widgets/smart_cover.dart';

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

  Widget _buildCover(HistoryModel historyItem) {
    // Convert HistoryModel to SongModel to use SmartCover
    final song = SongModel(
      id: historyItem.id,
      title: historyItem.title,
      author: historyItem.author,
      duration: Duration(milliseconds: historyItem.durationMs),
      coverUrl: historyItem.coverUrl,
      coverBytes: historyItem.coverBytes,
    );
    return SmartCover(
      song: song,
      size: 50,
      borderRadius: 8.0,
    );
  }

  void _playSong(HistoryModel historyItem, int index) {
    final audioProvider = context.read<AudioProvider>();
    
    // We must convert HistoryModel back to SongModel
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
  
  bool _isDownloaded(HistoryModel item) {
    if (item.id.startsWith('/')) {
      return File(item.id).existsSync();
    }
    
    final libProvider = locator<LocalLibraryProvider>();
    for (var song in libProvider.songs) {
      if (song.localPath != null && (song.localPath!.contains(item.id) || song.title == item.title)) {
        return true;
      }
    }
    return false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} дн. тому';
    if (diff.inHours > 0) return '${diff.inHours} год. тому';
    if (diff.inMinutes > 0) return '${diff.inMinutes} хв. тому';
    return 'Щойно';
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
                    final bool isDownloaded = _isDownloaded(item);
                    
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
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: _buildCover(item),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              isDownloaded ? Icons.offline_pin : Icons.cloud_outlined,
                              size: 14,
                              color: isDownloaded ? Colors.greenAccent : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${item.author} • ${_formatDate(item.lastPlayedAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isDownloaded && !item.id.startsWith('/'))
                              SongDownloadButton(
                                song: SongModel(
                                  id: item.id,
                                  title: item.title,
                                  author: item.author,
                                  coverUrl: item.coverUrl,
                                  duration: Duration(milliseconds: item.durationMs),
                                  isLocal: false,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow, size: 14, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.playCount}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _playSong(item, index),
                      ),
                    );
                  },
                ),
    );
  }
}
