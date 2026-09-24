import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/player_header.dart';
import '../widgets/player_controls.dart';
import '../widgets/visualizer_settings_sheet.dart';
import 'queue_screen.dart';
import 'lyrics_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Now Playing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lyrics_outlined, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LyricsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QueueScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 28),
            onSelected: (value) {
              if (value == 'visualizer') {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const VisualizerSettingsSheet(),
                );
              } else if (value == 'sleep_timer') {
                _showSleepTimerDialog(context, audioProvider);
              } else if (value == 'equalizer') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Еквалайзер на стадії розробки')));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'visualizer',
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 20),
                    SizedBox(width: 12),
                    Text('Налаштування візуалізатора'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'sleep_timer',
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Таймер сну'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'equalizer',
                child: Row(
                  children: [
                    Icon(Icons.equalizer, size: 20),
                    SizedBox(width: 12),
                    Text('Еквалайзер'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.5),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PlayerHeader(song: song),

                // Visualizer or Error
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: audioProvider.playbackError != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off, color: Colors.redAccent, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                audioProvider.playbackError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      : AudioVisualizer(isPlaying: audioProvider.isPlaying),
                ),

                PlayerControls(song: song),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, AudioProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Таймер сну', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Музика автоматично зупиниться через обраний час.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (provider.sleepTimerEndTime != null) ...[
                Text(
                  'Таймер активний до ${provider.sleepTimerEndTime!.hour.toString().padLeft(2, '0')}:${provider.sleepTimerEndTime!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Вимкнути таймер', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    provider.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: Colors.white24),
              ],
              _buildTimerOption(context, provider, 15),
              _buildTimerOption(context, provider, 30),
              _buildTimerOption(context, provider, 45),
              _buildTimerOption(context, provider, 60),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(BuildContext context, AudioProvider provider, int minutes) {
    return ListTile(
      title: Text('$minutes хвилин', style: const TextStyle(color: Colors.white)),
      onTap: () {
        provider.setSleepTimer(Duration(minutes: minutes));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Таймер встановлено на $minutes хвилин')),
        );
      },
    );
  }
}
