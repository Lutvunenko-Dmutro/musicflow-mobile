import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';

class TelemetrySettingsCard extends StatefulWidget {
  const TelemetrySettingsCard({super.key});

  @override
  State<TelemetrySettingsCard> createState() => _TelemetrySettingsCardState();
}

class _TelemetrySettingsCardState extends State<TelemetrySettingsCard> {
  bool _consent = false;
  bool? _isServerOnline;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final granted = await TelemetryService.instance.isConsentGranted();
    if (mounted) setState(() => _consent = granted);
    _checkServer();
  }

  Future<void> _checkServer() async {
    final online = await TelemetryService.instance.checkServerHealth();
    if (mounted) setState(() => _isServerOnline = online);
  }

  Future<void> _toggleConsent(bool val) async {
    await TelemetryService.instance.setConsent(val);
    setState(() => _consent = val);
  }

  Future<void> _sendTestReport() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Увімкніть згоду на діагностику, щоб надіслати звіт!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isTesting = true);
    final success = await TelemetryService.instance.sendCrashReport(
      error: 'Тестовий звіт від користувача через Налаштування',
      extra: {'isUserInitiatedTest': true, 'note': 'Перевірка з\'єднання додатку з сервером'},
    );
    if (!mounted) return;
    setState(() => _isTesting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Тестовий звіт успішно отримано сервером!' : '❌ Не вдалося зв\'язатися з сервером'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Діагностика та збої', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_isServerOnline != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_isServerOnline! ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: (_isServerOnline! ? Colors.green : Colors.grey).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: _isServerOnline! ? Colors.greenAccent : Colors.grey),
                      const SizedBox(width: 5),
                      Text(_isServerOnline! ? 'Сервер онлайн' : 'Сервер офлайн', style: TextStyle(fontSize: 10, color: _isServerOnline! ? Colors.greenAccent : Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Згода на збір звітів про помилки'),
            subtitle: const Text('Передавати технічні логи та стек винятків розробнику для виправлення багів', style: TextStyle(fontSize: 12)),
            value: _consent,
            activeColor: Theme.of(context).primaryColor,
            onChanged: _toggleConsent,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _checkServer,
                  icon: const Icon(Icons.wifi_find_rounded, size: 16),
                  label: const Text('Перевірити зв\'язок'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _sendTestReport,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(_isTesting ? 'Відправка...' : 'Тестовий звіт'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
