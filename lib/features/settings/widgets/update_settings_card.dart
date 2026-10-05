import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/services/update_service.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_dialog.dart';

class UpdateSettingsCard extends StatefulWidget {
  const UpdateSettingsCard({super.key});

  @override
  State<UpdateSettingsCard> createState() => _UpdateSettingsCardState();
}

class _UpdateSettingsCardState extends State<UpdateSettingsCard> {
  bool _isChecking = false;
  String _serverUrl = TelemetryService.defaultServerUrl;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await TelemetryService.instance.getServerUrl();
    if (mounted) setState(() => _serverUrl = url);
  }

  Future<void> _checkUpdate() async {
    setState(() => _isChecking = true);
    final info = await UpdateService.instance.checkForUpdate();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (info != null) {
      UpdateDialog.show(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У вас встановлена найновіша версія! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editServerUrl() async {
    final controller = TextEditingController(text: _serverUrl);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Адреса сервера оновлень', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введіть IP-адресу вашого ПК з запущеним сервером:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: 'http://192.168.0.103:8080',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );

    if (newUrl != null && newUrl.isNotEmpty && mounted) {
      await TelemetryService.instance.setServerUrl(newUrl);
      setState(() => _serverUrl = newUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Сервер: $newUrl'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Оновлення додатку', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                child: const Text('v${UpdateService.currentVersion} (${UpdateService.currentBuildNumber})', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.dns_outlined, size: 22, color: Colors.white70),
            title: const Text('Сервер оновлень та телеметрії', style: TextStyle(fontSize: 13)),
            subtitle: Text(_serverUrl, style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace')),
            trailing: const Icon(Icons.edit_outlined, size: 18, color: Colors.white60),
            onTap: _editServerUrl,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkUpdate,
              icon: _isChecking
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_isChecking ? 'Перевірка оновлень...' : 'Перевірити оновлення зараз'),
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
