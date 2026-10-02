import 'dart:ui';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer_slider_setting.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer_style_chip.dart';

class VisualizerSettingsSheet extends StatelessWidget {
  const VisualizerSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Consumer<VisualizerSettingsProvider>(
            builder: (context, settings, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Налаштування',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        tooltip: 'Скинути до стандартних',
                        onPressed: () {
                          settings.reset();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  VisualizerSliderSetting(
                    icon: Icons.height,
                    label: 'Амплітуда (Висота)',
                    value: settings.amplitudeBoost.clamp(0.5, 1.20),
                    min: 0.5,
                    max: 1.20,
                    onChanged: settings.setAmplitudeBoost,
                  ),
                  VisualizerSliderSetting(
                    icon: Icons.speed,
                    label: 'Підйом (Attack)',
                    value: settings.attack,
                    min: 0.05,
                    max: 1.0,
                    onChanged: settings.setAttack,
                  ),
                  VisualizerSliderSetting(
                    icon: Icons.waves,
                    label: 'Падіння (Release)',
                    value: settings.release,
                    min: 0.01,
                    max: 0.5,
                    onChanged: settings.setRelease,
                  ),
                  VisualizerSliderSetting(
                    icon: Icons.arrow_downward,
                    label: 'Гравітація ліній',
                    value: settings.gravity.abs().clamp(0.0005, 0.02),
                    min: 0.0005,
                    max: 0.02,
                    fractionDigits: 4,
                    onChanged: (val) => settings.setGravity(-val),
                  ),
                  VisualizerSliderSetting(
                    icon: Icons.vertical_align_top,
                    label: 'Відскок ліній',
                    value: settings.bounce,
                    min: 0.0,
                    max: 0.2,
                    onChanged: settings.setBounce,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.palette, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Стиль візуалізації', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            VisualizerStyleChip(settings: settings, style: VisualizerStyle.bars, label: 'Смуги', icon: Icons.bar_chart),
                            const SizedBox(width: 8),
                            VisualizerStyleChip(settings: settings, style: VisualizerStyle.mirrored, label: 'Центр', icon: Icons.graphic_eq),
                            const SizedBox(width: 8),
                            VisualizerStyleChip(settings: settings, style: VisualizerStyle.circle, label: 'Коло', icon: Icons.radio_button_unchecked),
                            const SizedBox(width: 8),
                            VisualizerStyleChip(settings: settings, style: VisualizerStyle.wave, label: 'Хвиля', icon: Icons.waves),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.memory, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Ядро візуалізатора', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Software — FFT-аналіз хвилі (рекомендовано)\nHardware — пряме FFT від Android (може відрізнятись)',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CoreChip(
                              label: 'Software (FFT)',
                              icon: Icons.psychology,
                              selected: settings.core == VisualizerCore.software,
                              onTap: () => settings.setCore(VisualizerCore.software),
                            ),
                            const SizedBox(width: 8),
                            _CoreChip(
                              label: 'Hardware',
                              icon: Icons.developer_board,
                              selected: settings.core == VisualizerCore.hardware,
                              onTap: () => settings.setCore(VisualizerCore.hardware),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

}

class _CoreChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CoreChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Theme.of(context).primaryColor : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Theme.of(context).primaryColor : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : Colors.white60,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
