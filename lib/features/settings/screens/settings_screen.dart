import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/cache_info_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/download_settings_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_settings_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/telemetry_settings_card.dart';
import 'package:music_flow_mobile/features/settings/screens/visualizer_settings_screen.dart';
import 'package:music_flow_mobile/features/settings/screens/equalizer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showMediaNotification = true;
  bool _enableCrossfade = true;
  bool _smoothMediaPause = true;
  final String _language = 'Українська';
  String _downloadPath = 'Внутрішня пам\'ять/MusicFlow';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _downloadPath = prefs.getString('download_path') ?? 'За замовчуванням (Внутрішня пам\'ять)';
      _showMediaNotification = prefs.getBool('show_media_notification') ?? true;
      _enableCrossfade = prefs.getBool('enable_crossfade') ?? true;
      _smoothMediaPause = prefs.getBool('smooth_media_pause') ?? true;
    });
  }

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('download_path', selectedDirectory);
      setState(() {
        _downloadPath = selectedDirectory;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Папку змінено на: $selectedDirectory')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
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
                const Text('Відтворення', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Плавний перехід (Crossfade)'),
                  subtitle: const Text('Плавне затихання і перехід між треками', style: TextStyle(fontSize: 12)),
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
                  title: const Text('Плавна пауза при перегляді медіа'),
                  subtitle: const Text(
                    'Плавно зменшувати звук і зупиняти музику, якщо вмикається YouTube або інше відео',
                    style: TextStyle(fontSize: 12),
                  ),
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
                  title: const Text('Візуалізатор'),
                  subtitle: const Text('Живий перегляд, стилі та параметри анімації', style: TextStyle(fontSize: 12)),
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
                  title: const Text('Еквалайзер'),
                  subtitle: const Text('Частотні смуги, бас та пресети', style: TextStyle(fontSize: 12)),
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
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Система', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Мова'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Показувати сповіщення плеєра'),
                  subtitle: const Text('Вимкнення може зупиняти фонову музику', style: TextStyle(fontSize: 12)),
                  value: _showMediaNotification,
                  activeColor: primary,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('show_media_notification', val);
                    setState(() => _showMediaNotification = val);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Папка збереження'),
                  subtitle: Text(_downloadPath, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.folder, size: 20),
                  onTap: _pickDirectory,
                ),
              ],
            ),
          ),
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
