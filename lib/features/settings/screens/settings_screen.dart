import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/cache_info_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/download_settings_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_settings_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/telemetry_settings_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/system_settings_card.dart';
import 'package:music_flow_mobile/features/settings/screens/visualizer_settings_screen.dart';
import 'package:music_flow_mobile/features/settings/screens/equalizer_screen.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableCrossfade = true;
  bool _smoothMediaPause = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enableCrossfade = prefs.getBool('enable_crossfade') ?? true;
        _smoothMediaPause = prefs.getBool('smooth_media_pause') ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final strings = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const UpdateSettingsCard(),
          const SizedBox(height: 16),
          const TelemetrySettingsCard(),
          const SizedBox(height: 16),
          const DownloadSettingsCard(),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.playback, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.crossfadeTitle),
                  subtitle: Text(strings.crossfadeSubtitle, style: const TextStyle(fontSize: 12)),
                  value: _enableCrossfade,
                  activeColor: primary,
                  onChanged: (val) async {
                    setState(() => _enableCrossfade = val);
                    if (mounted) {
                      Provider.of<AudioProvider>(context, listen: false).toggleCrossfade();
                    }
                  },
                ),
                const Divider(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.smoothMediaPauseTitle),
                  subtitle: Text(strings.smoothMediaPauseSubtitle, style: const TextStyle(fontSize: 12)),
                  value: _smoothMediaPause,
                  activeColor: primary,
                  onChanged: (val) async {
                    setState(() => _smoothMediaPause = val);
                    if (mounted) {
                      Provider.of<AudioProvider>(context, listen: false).toggleSmoothMediaPause(val);
                    }
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.graphic_eq, color: primary),
                  title: Text(strings.visualizer),
                  subtitle: Text(strings.visualizerSubtitle, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VisualizerSettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.equalizer, color: primary),
                  title: Text(strings.equalizer),
                  subtitle: Text(strings.equalizerSubtitle, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EqualizerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const CacheInfoCard(),
          const SizedBox(height: 16),
          const SystemSettingsCard(),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Music Flow Mobile (Beta 1)\nby Lutvunenko-Dmutro',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
