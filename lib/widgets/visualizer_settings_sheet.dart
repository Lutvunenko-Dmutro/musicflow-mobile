import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visualizer_settings_provider.dart';

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
            color: const Color(0xFF161616).withValues(alpha: 0.7),
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
                  
                  _buildSlider(
                    icon: Icons.height,
                    label: 'Амплітуда (Висота)',
                    value: settings.amplitudeBoost.clamp(0.5, 1.20),
                    min: 0.5,
                    max: 1.20,
                    onChanged: settings.setAmplitudeBoost,
                  ),
                  _buildSlider(
                    icon: Icons.speed,
                    label: 'Підйом (Attack)',
                    value: settings.attack,
                    min: 0.05,
                    max: 1.0,
                    onChanged: settings.setAttack,
                  ),
                  _buildSlider(
                    icon: Icons.waves,
                    label: 'Падіння (Release)',
                    value: settings.release,
                    min: 0.01,
                    max: 0.5,
                    onChanged: settings.setRelease,
                  ),
                  _buildSlider(
                    icon: Icons.arrow_downward,
                    label: 'Гравітація ліній',
                    value: settings.gravity.abs().clamp(0.0005, 0.02),
                    min: 0.0005,
                    max: 0.02,
                    fractionDigits: 4,
                    onChanged: (val) => settings.setGravity(-val),
                  ),
                  _buildSlider(
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
                            _buildStyleChip(context, settings, VisualizerStyle.bars, 'Смуги', Icons.bar_chart),
                            const SizedBox(width: 8),
                            _buildStyleChip(context, settings, VisualizerStyle.mirrored, 'Центр', Icons.graphic_eq),
                            const SizedBox(width: 8),
                            _buildStyleChip(context, settings, VisualizerStyle.circle, 'Коло', Icons.radio_button_unchecked),
                            const SizedBox(width: 8),
                            _buildStyleChip(context, settings, VisualizerStyle.wave, 'Хвиля', Icons.waves),
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

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int fractionDigits = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                value.toStringAsFixed(fractionDigits),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFFE53935), // Theme primary
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFE53935).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(BuildContext context, VisualizerSettingsProvider settings, VisualizerStyle style, String label, IconData icon) {
    final isSelected = settings.style == style;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) settings.setStyle(style);
      },
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: Theme.of(context).primaryColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
