import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/dev_server_dialog.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_dialog.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_channel_dialogs.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/services/update_preferences.dart';
import 'package:music_flow_mobile/services/update_service.dart';

class UpdateSettingsCard extends StatefulWidget {
  const UpdateSettingsCard({super.key});

  @override
  State<UpdateSettingsCard> createState() => _UpdateSettingsCardState();
}

class _UpdateSettingsCardState extends State<UpdateSettingsCard> {
  bool _isChecking = false;
  String _installedVersion = '...';
  bool _autoCheck = true;
  UpdateFrequency _frequency = UpdateFrequency.onLaunch;
  UpdateChannel _channel = UpdateChannel.release;
  bool _systemNotif = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final vInfo = await UpdateService.instance.getCurrentVersion();
    final v = vInfo.version;
    final auto = await UpdatePreferences.isAutoCheckEnabled();
    final freq = await UpdatePreferences.getFrequency();
    final chan = await UpdatePreferences.getChannel();
    final notif = await UpdatePreferences.isSystemNotificationEnabled();
    if (mounted) {
      setState(() {
        _installedVersion = v;
        _autoCheck = auto;
        _frequency = freq;
        _channel = chan;
        _systemNotif = notif;
      });
    }
  }

  Future<void> _checkUpdate({bool allowChannelSwitch = false}) async {
    final l10n = context.l10n;
    setState(() => _isChecking = true);
    final info = await UpdateService.instance.checkForUpdate(
      force: true,
      allowChannelSwitch: allowChannelSwitch,
    );
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (info != null) {
      UpdateDialog.show(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.latestVersionInstalled), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _selectFrequency() async {
    final selected = await UpdateChannelDialogs.showFrequencyDialog(context, _frequency);
    if (selected != null && mounted) {
      await UpdatePreferences.setFrequency(selected);
      setState(() => _frequency = selected);
    }
  }

  Future<void> _selectChannel() async {
    final selected = await UpdateChannelDialogs.showChannelDialog(context, _channel);
    if (selected != null && selected != _channel && mounted) {
      await UpdatePreferences.setChannel(selected);
      setState(() => _channel = selected);
      if (!mounted) return;
      final confirm = await UpdateChannelDialogs.showConfirmChannelSwitch(context, selected);
      if (confirm == true && mounted) {
        _checkUpdate(allowChannelSwitch: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final l10n = context.l10n;
    final isChannelDiff = _channel != UpdatePreferences.currentRunningChannel;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.updateSettingsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => DevServerDialog.show(context),
                onLongPress: () => DevServerDialog.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_tethering_rounded, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'v$_installedVersion (${UpdatePreferences.currentRunningChannel == UpdateChannel.release ? "Release" : "Debug"})',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.autoCheckTitle),
            subtitle: Text(l10n.autoCheckSubtitle, style: const TextStyle(fontSize: 12)),
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
              title: Text(l10n.checkFrequency),
              subtitle: Text(_frequency.localizedLabel(l10n), style: TextStyle(fontSize: 12, color: primary)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _selectFrequency,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.systemNotificationsTitle),
              subtitle: Text(l10n.systemNotificationsSubtitle, style: const TextStyle(fontSize: 12)),
              value: _systemNotif,
              activeColor: primary,
              onChanged: (val) async {
                await UpdatePreferences.setSystemNotificationEnabled(val);
                setState(() => _systemNotif = val);
              },
            ),
          ],
          const Divider(color: Colors.white12, height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.manage_accounts_rounded, size: 20),
            title: Text(l10n.updateChannelTitle),
            subtitle: Text(
              isChannelDiff
                  ? '${_channel.localizedLabel(l10n)} • ${l10n.channelSwitchNeeded}'
                  : _channel.localizedLabel(l10n),
              style: TextStyle(fontSize: 12, color: isChannelDiff ? Colors.amber : primary),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: _selectChannel,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkUpdate,
              icon: _isChecking
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_isChecking ? l10n.checkingUpdates : l10n.checkUpdatesNow),
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
