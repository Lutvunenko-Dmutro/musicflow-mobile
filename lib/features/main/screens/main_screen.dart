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
import 'package:music_flow_mobile/services/update_preferences.dart';
import 'package:music_flow_mobile/services/update_service.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

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

    final shouldCheck = await UpdatePreferences.shouldCheckNow();
    if (!shouldCheck) return;

    final info = await UpdateService.instance.checkForUpdate();
    if (info != null && mounted) {
      UpdateDialog.show(context, info);
      await UpdatePreferences.recordCheckTime();

      final systemNotif = await UpdatePreferences.isSystemNotificationEnabled();
      if (systemNotif) {
        await UpdateService.instance.showSystemNotification(
          title: 'Доступне оновлення MusicFlow v${info.version}',
          message: 'Натисніть, щоб переглянути нові функції та оновити додаток',
        );
      }
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
                  ...List.generate(_screens.length, (i) {
                    final isCurrent = i == _currentIndex;
                    return IgnorePointer(
                      ignoring: !isCurrent,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        offset: isCurrent ? Offset.zero : Offset(i < _currentIndex ? -0.06 : 0.06, 0.0),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          opacity: isCurrent ? 1.0 : 0.0,
                          child: _screens[i],
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    left: 24,
                    right: 24,
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: context.l10n.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_outlined),
            selectedIcon: const Icon(Icons.library_music),
            label: context.l10n.library,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: context.l10n.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.l10n.settings,
          ),
        ],
      ),
    );
  }
}
