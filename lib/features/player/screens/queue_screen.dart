import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final queue = audioProvider.queue;
    final currentIndex = audioProvider.currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Черга відтворення', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: queue.isEmpty
          ? const Center(child: Text('Черга порожня', style: TextStyle(color: Colors.white54)))
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: queue.length,
              onReorder: (oldIndex, newIndex) {
                audioProvider.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = queue[index];
                final isPlaying = index == currentIndex;
                
                return Dismissible(
                  key: ValueKey('${song.id}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.withValues(alpha: 0.8),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    audioProvider.removeFromQueue(index);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    tileColor: isPlaying ? Theme.of(context).primaryColor.withValues(alpha: 0.15) : null,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPlaying)
                          Icon(Icons.equalizer, color: Theme.of(context).primaryColor, size: 20)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 12),
                        SmartCover(song: song, size: 48, borderRadius: 6.0),
                      ],
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        color: isPlaying ? Theme.of(context).primaryColor : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      song.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(song.duration),
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle, color: Colors.white38),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (index != currentIndex) {
                        // Skip directly to this song in the queue
                        // We can just set the queue again with the new index
                        audioProvider.setQueue(queue, initialIndex: index);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
