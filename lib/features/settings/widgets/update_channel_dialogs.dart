import 'package:flutter/material.dart';
import 'package:music_flow_mobile/services/update_preferences.dart';

class UpdateChannelDialogs {
  static Future<UpdateFrequency?> showFrequencyDialog(BuildContext context, UpdateFrequency current) {
    return showDialog<UpdateFrequency>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Частота перевірки оновлень', style: TextStyle(color: Colors.white, fontSize: 16)),
        children: UpdateFrequency.values.map((f) => RadioListTile<UpdateFrequency>(
          title: Text(f.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          value: f,
          groupValue: current,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (val) => Navigator.pop(ctx, val),
        )).toList(),
      ),
    );
  }

  static Future<UpdateChannel?> showChannelDialog(BuildContext context, UpdateChannel current) {
    return showDialog<UpdateChannel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Канал оновлень', style: TextStyle(color: Colors.white, fontSize: 16)),
        children: UpdateChannel.values.map((c) => RadioListTile<UpdateChannel>(
          title: Text(c.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          value: c,
          groupValue: current,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (val) => Navigator.pop(ctx, val),
        )).toList(),
      ),
    );
  }

  static Future<bool?> showConfirmChannelSwitch(BuildContext context, UpdateChannel selected) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Зміна каналу оновлень', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Ви обрали канал ${selected == UpdateChannel.release ? "Release" : "Debug"}.\n\n'
          'Бажаєте зараз завантажити та встановити відповідну збірку?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Пізніше', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Завантажити зараз'),
          ),
        ],
      ),
    );
  }
}
