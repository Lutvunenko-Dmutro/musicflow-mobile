import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/mini_player.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/audio_visualizer.dart';
import 'package:music_flow_mobile/features/search/screens/search_screen.dart';
import 'package:music_flow_mobile/features/library/screens/library_screen.dart';
import 'package:music_flow_mobile/features/library/screens/history_screen.dart';
import 'package:music_flow_mobile/features/settings/screens/settings_screen.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_dialog.dart';
import 'package:music_flow_mobile/services/update_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
    LibraryScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
    });
  }

  Future<void> _checkAutoUpdate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final info = await UpdateService.instance.checkForUpdate();
    if (info != null && mounted) {
      UpdateDialog.show(context, info);
    }
  }

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
                  IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Consumer<AudioProvider>(
                        builder: (context, audioProvider, child) {
                          if (audioProvider.isPlaying && audioProvider.showVisualizer) {
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Пошук',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Медіатека',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Історія',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Налаштування',
          ),
        ],
      ),
    );
  }
}
