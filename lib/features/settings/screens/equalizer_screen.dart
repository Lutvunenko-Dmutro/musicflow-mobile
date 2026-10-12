import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/audio_visualizer.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_presets.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_bands.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_knobs.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_playback_bar.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    return ChangeNotifierProvider.value(
      value: audioProvider.equalizerProvider,
      child: const _EqualizerScreenBody(),
    );
  }
}

class _EqualizerScreenBody extends StatefulWidget {
  const _EqualizerScreenBody();

  @override
  State<_EqualizerScreenBody> createState() => _EqualizerScreenBodyState();
}

class _EqualizerScreenBodyState extends State<_EqualizerScreenBody> {
  String _activePreset = 'Налаштувати';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EqualizerProvider>(context);
    final audioProvider = context.watch<AudioProvider>();
    final isEnabled = provider.isEnabled;
    final primary = Theme.of(context).primaryColor;
    final l10n = context.l10n;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.parameters == null) {
        provider.initIfNeeded();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(l10n.equalizerTitle),
        backgroundColor: Colors.transparent,
        actions: [
          if (isEnabled)
            TextButton.icon(
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(l10n.reset, style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.resetPreset();
                setState(() => _activePreset = 'Звичайний');
              },
            ),
          Switch(
            value: isEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              provider.toggleEqualizer();
            },
            activeColor: primary,
          ),
        ],
      ),
      body: !isEnabled
          ? Center(
              child: Text(
                l10n.equalizerDisabled,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: AudioVisualizer(
                    isPlaying: audioProvider.isPlaying,
                    width: MediaQuery.of(context).size.width,
                    height: 100,
                  ),
                ),
                EqualizerPlaybackBar(audioProvider: audioProvider),
                const SizedBox(height: 16),
                EqualizerBandsWidget(
                  provider: provider,
                  onBandChanged: (index, val) {
                    setState(() => _activePreset = 'Налаштувати');
                    provider.setBandGain(index, val);
                  },
                ),
                const SizedBox(height: 28),
                EqualizerKnobsWidget(provider: provider),
                const SizedBox(height: 28),
                EqualizerPresetsWidget(
                  activePreset: _activePreset,
                  onPresetSelected: (preset) {
                    setState(() => _activePreset = preset);
                    provider.applyPreset(preset);
                  },
                ),
                const SizedBox(height: 28),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        try {
                          final sessionId = audioProvider.player.androidAudioSessionId;
                          const ch = MethodChannel('com.example.music_flow_mobile/visualizer_method');
                          await ch.invokeMethod('openSystemEqualizer', {'sessionId': sessionId});
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.systemSoundSettingsError)),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252528),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primary.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.tune_rounded, color: primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.systemSoundEffectsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  Text(l10n.systemSoundEffectsSubtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
    );
  }
}
