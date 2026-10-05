import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

class VisualizerCoreSelector extends StatelessWidget {
  final VisualizerSettingsProvider settings;

  const VisualizerCoreSelector({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isHw = settings.core == VisualizerCore.hardware;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              title: 'Програмне (Software FFT)',
              subtitle: 'Вбудований точний аналіз',
              isSelected: !isHw,
              primary: primary,
              onTap: () {
                HapticFeedback.lightImpact();
                settings.setCore(VisualizerCore.software);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildButton(
              title: 'Апаратне (Hardware)',
              subtitle: 'Android AudioEffect API',
              isSelected: isHw,
              primary: primary,
              onTap: () {
                HapticFeedback.lightImpact();
                settings.setCore(VisualizerCore.hardware);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primary : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? primary : Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? primary.withValues(alpha: 0.8) : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
