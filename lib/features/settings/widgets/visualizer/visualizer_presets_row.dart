import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

class VisualizerPresetsRow extends StatelessWidget {
  final VisualizerSettingsProvider settings;
  final String activePreset;
  final ValueChanged<String> onSelectPreset;

  const VisualizerPresetsRow({
    super.key,
    required this.settings,
    required this.activePreset,
    required this.onSelectPreset,
  });

  static const List<String> presets = [
    'Класичний',
    'Динамічний Бас',
    'Плавна Хвиля',
    'Неонове Коло',
    'Стерео Дзеркало',
    'Мінімалізм',
  ];

  static void applyPreset(String name, VisualizerSettingsProvider settings) {
    switch (name) {
      case 'Класичний':
        settings.setStyle(VisualizerStyle.bars);
        settings.setAmplitudeBoost(1.0);
        settings.setAttack(0.60);
        settings.setRelease(0.40);
        settings.setGravity(-0.008);
        settings.setBounce(0.06);
        break;
      case 'Динамічний Бас':
        settings.setStyle(VisualizerStyle.bars);
        settings.setAmplitudeBoost(1.35);
        settings.setAttack(0.85);
        settings.setRelease(0.30);
        settings.setGravity(-0.012);
        settings.setBounce(0.08);
        break;
      case 'Плавна Хвиля':
        settings.setStyle(VisualizerStyle.wave);
        settings.setAmplitudeBoost(1.0);
        settings.setAttack(0.40);
        settings.setRelease(0.18);
        settings.setGravity(-0.004);
        settings.setBounce(0.02);
        break;
      case 'Неонове Коло':
        settings.setStyle(VisualizerStyle.circle);
        settings.setAmplitudeBoost(1.20);
        settings.setAttack(0.70);
        settings.setRelease(0.30);
        settings.setGravity(-0.008);
        settings.setBounce(0.05);
        break;
      case 'Стерео Дзеркало':
        settings.setStyle(VisualizerStyle.mirrored);
        settings.setAmplitudeBoost(1.15);
        settings.setAttack(0.65);
        settings.setRelease(0.35);
        settings.setGravity(-0.009);
        settings.setBounce(0.06);
        break;
      case 'Мінімалізм':
        settings.setStyle(VisualizerStyle.bars);
        settings.setAmplitudeBoost(0.85);
        settings.setAttack(0.50);
        settings.setRelease(0.22);
        settings.setGravity(-0.006);
        settings.setBounce(0.01);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = presets[index];
          final isSelected = activePreset == p;

          return ChoiceChip(
            label: Text(p),
            selected: isSelected,
            onSelected: (_) {
              HapticFeedback.lightImpact();
              applyPreset(p, settings);
              onSelectPreset(p);
            },
            selectedColor: primary,
            backgroundColor: const Color(0xFF1E1E24),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.white70,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: isSelected ? primary : Colors.white12),
          );
        },
      ),
    );
  }
}
