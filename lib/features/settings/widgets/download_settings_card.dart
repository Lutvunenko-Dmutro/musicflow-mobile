import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

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
    final strings = context.l10n;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.downloadSettingsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.embedLyricsTitle),
            subtitle: Text(strings.embedLyricsSubtitle, style: const TextStyle(fontSize: 12)),
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
            title: Text(strings.highQualityTitle),
            subtitle: Text(strings.highQualitySubtitle, style: const TextStyle(fontSize: 12)),
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
