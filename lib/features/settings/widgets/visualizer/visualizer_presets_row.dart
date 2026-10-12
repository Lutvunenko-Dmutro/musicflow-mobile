import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
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

  static const List<String> presetKeys = [
    'classic',
    'dynamic_bass',
    'smooth_wave',
    'neon_circle',
    'stereo_mirror',
    'minimal',
  ];

  static String getPresetLabel(String key, AppStrings l10n) {
    switch (key) {
      case 'classic':
      case 'Класичний':
        return l10n.visPresetClassic;
      case 'dynamic_bass':
      case 'Динамічний Бас':
        return l10n.visPresetDynamicBass;
      case 'smooth_wave':
      case 'Плавна Хвиля':
        return l10n.visPresetSmoothWave;
      case 'neon_circle':
      case 'Неонове Коло':
        return l10n.visPresetNeonCircle;
      case 'stereo_mirror':
      case 'Стерео Дзеркало':
        return l10n.visPresetStereoMirror;
      case 'minimal':
      case 'Мінімалізм':
        return l10n.visPresetMinimal;
      default:
        return l10n.visCustom;
    }
  }

  static void applyPreset(String key, VisualizerSettingsProvider settings) {
    switch (key) {
      case 'classic':
      case 'Класичний':
        settings.setStyle(VisualizerStyle.bars);
        settings.setAmplitudeBoost(1.0);
        settings.setAttack(0.60);
        settings.setRelease(0.40);
        settings.setGravity(-0.008);
        settings.setBounce(0.06);
        break;
      case 'dynamic_bass':
      case 'Динамічний Бас':
        settings.setStyle(VisualizerStyle.bars);
        settings.setAmplitudeBoost(1.35);
        settings.setAttack(0.85);
        settings.setRelease(0.30);
        settings.setGravity(-0.012);
        settings.setBounce(0.08);
        break;
      case 'smooth_wave':
      case 'Плавна Хвиля':
        settings.setStyle(VisualizerStyle.wave);
        settings.setAmplitudeBoost(1.0);
        settings.setAttack(0.40);
        settings.setRelease(0.18);
        settings.setGravity(-0.004);
        settings.setBounce(0.02);
        break;
      case 'neon_circle':
      case 'Неонове Коло':
        settings.setStyle(VisualizerStyle.circle);
        settings.setAmplitudeBoost(1.20);
        settings.setAttack(0.70);
        settings.setRelease(0.30);
        settings.setGravity(-0.008);
        settings.setBounce(0.05);
        break;
      case 'stereo_mirror':
      case 'Стерео Дзеркало':
        settings.setStyle(VisualizerStyle.mirrored);
        settings.setAmplitudeBoost(1.15);
        settings.setAttack(0.65);
        settings.setRelease(0.35);
        settings.setGravity(-0.009);
        settings.setBounce(0.06);
        break;
      case 'minimal':
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
    final l10n = context.l10n;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presetKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = presetKeys[index];
          final label = getPresetLabel(key, l10n);
          final isSelected = activePreset == key || activePreset == label;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              HapticFeedback.lightImpact();
              applyPreset(key, settings);
              onSelectPreset(key);
            },
            selectedColor: primary,
            backgroundColor: const Color(0xFF1E1E24),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? primary : Colors.white10,
              ),
            ),
          );
        },
      ),
    );
  }
}
