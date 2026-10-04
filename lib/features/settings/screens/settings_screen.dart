import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/features/settings/widgets/cache_info_card.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _embedLyrics = true;
  bool _highQuality = true;
  bool _showMediaNotification = true;
  bool _enableCrossfade = true;
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
      _embedLyrics = prefs.getBool('embed_lyrics') ?? true;
      _highQuality = prefs.getBool('high_quality') ?? true;
      _enableCrossfade = prefs.getBool('enable_crossfade') ?? true;
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

  Future<void> _clearHistory() async {
    await locator<DatabaseService>().clearHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Історію очищено!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Опції завантаження',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Вшити текст пісні'),
                  subtitle: const Text('Автоматично шукати текст і зберігати у файл', style: TextStyle(fontSize: 12)),
                  value: _embedLyrics,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('embed_lyrics', val);
                    setState(() => _embedLyrics = val);
                  },
                ),
                SwitchListTile(
                  title: const Text('Найкраща якість аудіо'),
                  subtitle: const Text('Завантажувати найбільший бітрейт (потребує більше пам\'яті)', style: TextStyle(fontSize: 12)),
                  value: _highQuality,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('high_quality', val);
                    setState(() => _highQuality = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Відтворення',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Плавний перехід (Crossfade)'),
                  subtitle: const Text('Плавне затихання і перехід між треками', style: TextStyle(fontSize: 12)),
                  value: _enableCrossfade,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (val) async {
                    setState(() => _enableCrossfade = val);
                    if (mounted) {
                      Provider.of<AudioProvider>(context, listen: false).toggleCrossfade();
                    }
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
                const Text(
                  'Система',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Мова'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Show language picker
                  },
                ),
                SwitchListTile(
                  title: const Text('Показувати сповіщення плеєра'),
                  subtitle: const Text('Вимкнення може зупиняти фонову музику', style: TextStyle(fontSize: 12)),
                  value: _showMediaNotification,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('show_media_notification', val);
                    setState(() => _showMediaNotification = val);
                  },
                ),
                ListTile(
                  title: const Text('Папка збереження'),
                  subtitle: Text(_downloadPath, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.folder, size: 20),
                  onTap: _pickDirectory,
                ),
                ListTile(
                  title: const Text('Очистити історію пошуку та відтворення'),
                  subtitle: const Text('Видалити всі записи з вкладки "Історія"'),
                  trailing: const Icon(Icons.history, color: Colors.orange, size: 20),
                  onTap: _clearHistory,
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
