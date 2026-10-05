import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/audio_visualizer.dart';

class VisualizerLivePreviewCard extends StatelessWidget {
  final AudioProvider audioProvider;
  final VisualizerSettingsProvider settings;
  final bool forceTestMode;
  final ValueChanged<bool> onToggleTestMode;

  const VisualizerLivePreviewCard({
    super.key,
    required this.audioProvider,
    required this.settings,
    required this.forceTestMode,
    required this.onToggleTestMode,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isPlaying = audioProvider.isPlaying;
    final isVisEnabled = audioProvider.showVisualizer;
    final currentSong = audioProvider.currentSong;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVisEnabled ? primary.withValues(alpha: 0.35) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isVisEnabled ? primary.withValues(alpha: 0.12) : Colors.black45,
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !isVisEnabled
                            ? Colors.grey
                            : (isPlaying ? Colors.greenAccent : Colors.orangeAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      !isVisEnabled
                          ? 'Вимкнено'
                          : (isPlaying ? 'В ефірі (Трек)' : 'Тестовий біт'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleTestMode(!forceTestMode);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: forceTestMode ? primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: forceTestMode ? primary.withValues(alpha: 0.5) : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: forceTestMode ? primary : Colors.white60),
                        const SizedBox(width: 4),
                        Text(
                          'Демо-сигнал',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: forceTestMode ? primary : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 75,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isVisEnabled)
                    const Center(
                      child: Text(
                        'Візуалізатор вимкнено перемикачем угорі',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  else
                    AudioVisualizer(
                      isPlaying: isPlaying,
                      testMode: forceTestMode || !isPlaying,
                      height: 75,
                      barCount: 60,
                      width: double.infinity,
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong?.title ?? 'Музику не вибрано',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        currentSong?.author ?? 'Увімкніть трек для живої реакції',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 22, color: Colors.white70),
                  onPressed: () => audioProvider.playPrevious(),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 36,
                    color: primary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.resume();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 22, color: Colors.white70),
                  onPressed: () => audioProvider.playNext(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
