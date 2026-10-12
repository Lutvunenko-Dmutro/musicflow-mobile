import 'package:flutter/material.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/services/server_discovery_service.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';

class DevServerDialog {
  static Future<void> show(BuildContext context) async {
    final currentUrl = await TelemetryService.instance.getServerUrl();
    if (!context.mounted) return;
    final controller = TextEditingController(text: currentUrl);
    final l10n = context.l10n;

    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: Text(l10n.devServerTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.devServerSubtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: TelemetryService.defaultServerUrl,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.wifi_find_rounded, size: 14),
                  label: const Text('Знайти в Wi-Fi', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final found = await ServerDiscoveryService.discoverLocalServer();
                    if (found != null) controller.text = found;
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.restore_rounded, size: 14),
                  label: Text(l10n.devServerDefaultPreset, style: const TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = TelemetryService.defaultServerUrl,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newUrl != null && newUrl.isNotEmpty && context.mounted) {
      await TelemetryService.instance.setServerUrl(newUrl);
      final ok = await TelemetryService.instance.checkServerHealth();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? l10n.devServerConnected(newUrl) : l10n.devServerUnreachable(newUrl)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
