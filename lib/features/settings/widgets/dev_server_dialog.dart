import 'package:flutter/material.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';

class DevServerDialog {
  static Future<void> show(BuildContext context) async {
    final currentUrl = await TelemetryService.instance.getServerUrl();
    if (!context.mounted) return;
    final controller = TextEditingController(text: currentUrl);

    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Налаштування сервера (Dev Mode)', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Адреса сервера оновлень та телеметрії:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: 'http://192.168.0.103:8080',
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

    if (newUrl != null && newUrl.isNotEmpty && context.mounted) {
      await TelemetryService.instance.setServerUrl(newUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Адресу сервера змінено: $newUrl'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
