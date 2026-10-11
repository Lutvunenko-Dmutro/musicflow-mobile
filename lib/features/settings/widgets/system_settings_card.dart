import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/language_selector_sheet.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/providers/language_provider.dart';

class SystemSettingsCard extends StatefulWidget {
  const SystemSettingsCard({super.key});

  @override
  State<SystemSettingsCard> createState() => _SystemSettingsCardState();
}

class _SystemSettingsCardState extends State<SystemSettingsCard> {
  bool _showMediaNotification = true;
  String _downloadPath = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _downloadPath = prefs.getString('download_path') ?? '';
        _showMediaNotification = prefs.getBool('show_media_notification') ?? true;
      });
    }
  }

  Future<void> _pickDirectory() async {
    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('download_path', selectedDirectory);
      if (mounted) {
        setState(() => _downloadPath = selectedDirectory);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Папку змінено на: $selectedDirectory')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final strings = context.l10n;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage;
    final displayPath = _downloadPath.isEmpty ? strings.defaultFolder : _downloadPath;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.system, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(currentLang.flag, style: const TextStyle(fontSize: 22)),
            title: Text(strings.language),
            subtitle: Text('${currentLang.title} • ${currentLang.subtitle}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => LanguageSelectorSheet.show(context),
          ),
          const Divider(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.mediaNotificationTitle),
            subtitle: Text(strings.mediaNotificationSubtitle, style: const TextStyle(fontSize: 12)),
            value: _showMediaNotification,
            activeColor: primary,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('show_media_notification', val);
              setState(() => _showMediaNotification = val);
            },
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.downloadFolderTitle),
            subtitle: Text(displayPath, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.folder, size: 20),
            onTap: _pickDirectory,
          ),
        ],
      ),
    );
  }
}
