import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../widgets/custom_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SongModel> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // For now, we load all downloaded songs.
    // In a full implementation, you'd have a separate 'history' table for played songs.
    final songs = await DatabaseService.instance.getAllSongs();
    setState(() {
      _history = songs.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Історія'),
      ),
      body: _history.isEmpty
          ? const Center(child: Text('Історія порожня'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final song = _history[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CustomCard(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            song.coverUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                song.author,
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            context.read<AudioProvider>().playSong(song);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
