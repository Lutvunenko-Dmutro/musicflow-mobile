import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class TelemetrySettingsCard extends StatefulWidget {
  const TelemetrySettingsCard({super.key});

  @override
  State<TelemetrySettingsCard> createState() => _TelemetrySettingsCardState();
}

class _TelemetrySettingsCardState extends State<TelemetrySettingsCard> {
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final granted = await TelemetryService.instance.isConsentGranted();
    if (mounted) setState(() => _consent = granted);
  }

  Future<void> _toggleConsent(bool val) async {
    await TelemetryService.instance.setConsent(val);
    setState(() => _consent = val);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.privacyAndDiagnostics, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.crashConsentTitle),
            subtitle: Text(
              strings.crashConsentSubtitle,
              style: const TextStyle(fontSize: 12),
            ),
            value: _consent,
            activeColor: Theme.of(context).primaryColor,
            onChanged: _toggleConsent,
          ),
        ],
      ),
    );
  }
}
