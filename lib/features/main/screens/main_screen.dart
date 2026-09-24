import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/mini_player.dart';
import 'package:music_flow_mobile/features/player/widgets/audio_visualizer.dart';
import 'package:music_flow_mobile/features/search/screens/search_screen.dart';
import 'package:music_flow_mobile/features/library/screens/library_screen.dart';
import 'package:music_flow_mobile/features/library/screens/history_screen.dart';
import 'package:music_flow_mobile/features/settings/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SearchScreen(),
    const LibraryScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        left: true,
        right: true,
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _screens[_currentIndex],
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Consumer<AudioProvider>(
                        builder: (context, audioProvider, child) {
                          if (audioProvider.isPlaying) {
                            return const SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: AudioVisualizer(
                                isPlaying: true,
                                width: double.infinity,
                                height: 50,
                                barCount: 60,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Головна',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Бібліотека',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Історія',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Налаштування',
          ),
        ],
      ),
    );
  }
}
