import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

class VisualizerSlidersCard extends StatelessWidget {
  final VisualizerSettingsProvider settings;
  final VoidCallback onValuesChanged;

  const VisualizerSlidersCard({
    super.key,
    required this.settings,
    required this.onValuesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildRow(
            context,
            icon: Icons.vertical_align_top,
            label: 'Чутливість / Висота',
            desc: 'Множник підйому смуг від звуку',
            value: settings.amplitudeBoost.clamp(0.5, 2.0),
            min: 0.5,
            max: 2.0,
            valueLabel: '${settings.amplitudeBoost.toStringAsFixed(2)}x',
            onChanged: (val) {
              settings.setAmplitudeBoost(val);
              onValuesChanged();
            },
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildRow(
            context,
            icon: Icons.speed,
            label: 'Швидкість підйому (Attack)',
            desc: 'Як швидко стовпчики реагують на бас',
            value: settings.attack.clamp(0.05, 1.0),
            min: 0.05,
            max: 1.0,
            valueLabel: settings.attack.toStringAsFixed(2),
            onChanged: (val) {
              settings.setAttack(val);
              onValuesChanged();
            },
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildRow(
            context,
            icon: Icons.trending_down,
            label: 'Плавність затухання (Release)',
            desc: 'Швидкість опускання смуг після піку',
            value: settings.release.clamp(0.01, 0.5),
            min: 0.01,
            max: 0.5,
            valueLabel: settings.release.toStringAsFixed(2),
            onChanged: (val) {
              settings.setRelease(val);
              onValuesChanged();
            },
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildRow(
            context,
            icon: Icons.arrow_downward,
            label: 'Гравітація пікових крапок',
            desc: 'Прискорення падіння верхніх точок',
            value: settings.gravity.abs().clamp(0.0005, 0.02),
            min: 0.0005,
            max: 0.02,
            valueLabel: settings.gravity.toStringAsFixed(4),
            onChanged: (val) {
              settings.setGravity(-val);
              onValuesChanged();
            },
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildRow(
            context,
            icon: Icons.sports_basketball,
            label: 'Пружність відскоку (Bounce)',
            desc: 'Ефект пружини при різких ударах',
            value: settings.bounce.clamp(0.0, 0.15),
            min: 0.0,
            max: 0.15,
            valueLabel: settings.bounce.toStringAsFixed(3),
            onChanged: (val) {
              settings.setBounce(val);
              onValuesChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String desc,
    required double value,
    required double min,
    required double max,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white38)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primary,
              inactiveTrackColor: Colors.white12,
              thumbColor: primary,
              overlayColor: primary.withValues(alpha: 0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
}
