import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadSettingsCard extends StatefulWidget {
  const DownloadSettingsCard({super.key});

  @override
  State<DownloadSettingsCard> createState() => _DownloadSettingsCardState();
}

class _DownloadSettingsCardState extends State<DownloadSettingsCard> {
  bool _embedLyrics = true;
  bool _highQuality = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _embedLyrics = prefs.getBool('embed_lyrics') ?? true;
        _highQuality = prefs.getBool('high_quality') ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Опції завантаження', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Вшити текст пісні'),
            subtitle: const Text('Автоматично шукати текст і зберігати у файл', style: TextStyle(fontSize: 12)),
            value: _embedLyrics,
            activeColor: primary,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('embed_lyrics', val);
              setState(() => _embedLyrics = val);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Найкраща якість аудіо'),
            subtitle: const Text('Завантажувати найбільший бітрейт (потребує більше пам\'яті)', style: TextStyle(fontSize: 12)),
            value: _highQuality,
            activeColor: primary,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('high_quality', val);
              setState(() => _highQuality = val);
            },
          ),
        ],
      ),
    );
  }
}
