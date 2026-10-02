import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class SleepTimerDialog extends StatelessWidget {
  final AudioProvider provider;

  const SleepTimerDialog({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Таймер сну', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Музика автоматично зупиниться через обраний час.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (provider.sleepTimerEndTime != null) ...[
            Text(
              'Таймер активний до ${provider.sleepTimerEndTime!.hour.toString().padLeft(2, '0')}:${provider.sleepTimerEndTime!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Вимкнути таймер', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                provider.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
          ],
          _buildTimerOption(context, provider, 15),
          _buildTimerOption(context, provider, 30),
          _buildTimerOption(context, provider, 45),
          _buildTimerOption(context, provider, 60),
        ],
      ),
    );
  }

  Widget _buildTimerOption(BuildContext context, AudioProvider provider, int minutes) {
    return ListTile(
      title: Text('$minutes хвилин', style: const TextStyle(color: Colors.white)),
      onTap: () {
        provider.setSleepTimer(Duration(minutes: minutes));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Таймер встановлено на $minutes хвилин')),
        );
      },
    );
  }
}
