import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class SleepTimerDialog extends StatelessWidget {
  final AudioProvider provider;

  const SleepTimerDialog({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text(strings.sleepTimer, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.sleepTimerDesc,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (provider.sleepTimerEndTime != null) ...[
            Text(
              '${strings.sleepTimerActiveUntil} ${provider.sleepTimerEndTime!.hour.toString().padLeft(2, '0')}:${provider.sleepTimerEndTime!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(strings.turnOffTimer, style: const TextStyle(color: Colors.redAccent)),
              onTap: () {
                provider.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
          ],
          _buildTimerOption(context, provider, 15, strings),
          _buildTimerOption(context, provider, 30, strings),
          _buildTimerOption(context, provider, 45, strings),
          _buildTimerOption(context, provider, 60, strings),
        ],
      ),
    );
  }

  Widget _buildTimerOption(BuildContext context, AudioProvider provider, int minutes, AppStrings strings) {
    return ListTile(
      title: Text('$minutes ${strings.minutesSuffix}', style: const TextStyle(color: Colors.white)),
      onTap: () {
        provider.setSleepTimer(Duration(minutes: minutes));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.timerSetTo} $minutes ${strings.minutesSuffix}')),
        );
      },
    );
  }
}
