import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/dev_server_dialog.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_dialog.dart';
import 'package:music_flow_mobile/services/update_preferences.dart';
import 'package:music_flow_mobile/services/update_service.dart';

class UpdateSettingsCard extends StatefulWidget {
  const UpdateSettingsCard({super.key});

  @override
  State<UpdateSettingsCard> createState() => _UpdateSettingsCardState();
}

class _UpdateSettingsCardState extends State<UpdateSettingsCard> {
  bool _isChecking = false;
  String _installedVersion = UpdateService.currentVersion;
  bool _autoCheck = true;
  UpdateFrequency _frequency = UpdateFrequency.onLaunch;
  bool _systemNotif = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final ver = await UpdateService.instance.getCurrentVersion();
    final auto = await UpdatePreferences.isAutoCheckEnabled();
    final freq = await UpdatePreferences.getFrequency();
    final notif = await UpdatePreferences.isSystemNotificationEnabled();
    if (mounted) {
      setState(() {
        _installedVersion = ver.version;
        _autoCheck = auto;
        _frequency = freq;
        _systemNotif = notif;
      });
    }
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

  Future<void> _selectFrequency() async {
    final selected = await showDialog<UpdateFrequency>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Частота перевірки оновлень', style: TextStyle(color: Colors.white, fontSize: 16)),
        children: UpdateFrequency.values.map((f) => RadioListTile<UpdateFrequency>(
          title: Text(f.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          value: f,
          groupValue: _frequency,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (val) => Navigator.pop(ctx, val),
        )).toList(),
      ),
    );

    if (selected != null && mounted) {
      await UpdatePreferences.setFrequency(selected);
      setState(() => _frequency = selected);
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
              GestureDetector(
                onLongPress: () => DevServerDialog.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                  child: Text('v$_installedVersion', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Автоматична перевірка'),
            subtitle: const Text('Шукати нові версії у фоновому режимі', style: TextStyle(fontSize: 12)),
            value: _autoCheck,
            activeColor: primary,
            onChanged: (val) async {
              await UpdatePreferences.setAutoCheckEnabled(val);
              setState(() => _autoCheck = val);
            },
          ),
          if (_autoCheck) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Частота перевірки'),
              subtitle: Text(_frequency.label, style: TextStyle(fontSize: 12, color: primary)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _selectFrequency,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Сповіщення на телефоні'),
              subtitle: const Text('Показувати повідомлення у шторці Android', style: TextStyle(fontSize: 12)),
              value: _systemNotif,
              activeColor: primary,
              onChanged: (val) async {
                await UpdatePreferences.setSystemNotificationEnabled(val);
                setState(() => _systemNotif = val);
              },
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkUpdate,
              icon: _isChecking
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_isChecking ? 'Перевірка оновлень...' : 'Перевірити оновлення зараз'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
