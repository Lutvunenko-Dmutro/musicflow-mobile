import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/audio_visualizer.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_presets.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_bands.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_knobs.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.parameters == null) {
        provider.initIfNeeded();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Еквалайзер'),
        backgroundColor: Colors.transparent,
        actions: [
          Switch(
            value: isEnabled,
            onChanged: (val) => provider.toggleEqualizer(),
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
      body: !isEnabled
          ? const Center(
              child: Text(
                'Еквалайзер вимкнено',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: AudioVisualizer(
                    isPlaying: audioProvider.isPlaying,
                    width: MediaQuery.of(context).size.width,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 24),
                EqualizerBandsWidget(
                  provider: provider,
                  onBandChanged: (index, val) {
                    setState(() => _activePreset = 'Налаштувати');
                    provider.setBandGain(index, val);
                  },
                ),
                const SizedBox(height: 32),
                EqualizerKnobsWidget(provider: provider),
                const SizedBox(height: 32),
                EqualizerPresetsWidget(
                  activePreset: _activePreset,
                  onPresetSelected: (preset) {
                    setState(() => _activePreset = preset);
                    provider.applyPreset(preset);
                  },
                ),
                const SizedBox(height: 32),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final audioProvider = context.read<AudioProvider>();
                        final sessionId = audioProvider.player.androidAudioSessionId;
                        const channel = MethodChannel('com.example.music_flow_mobile/visualizer_method');
                        await channel.invokeMethod('openSystemEqualizer', {'sessionId': sessionId});
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Не вдалося відкрити налаштування звуку')),
                        );
                      }
                    },
                    icon: const Icon(Icons.settings_suggest),
                    label: const Text('Системний еквалайзер / Звукові ефекти'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
    );
  }
}
