import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

class VisualizerStyleChip extends StatelessWidget {
  final VisualizerSettingsProvider settings;
  final VisualizerStyle style;
  final String label;
  final IconData icon;

  const VisualizerStyleChip({
    super.key,
    required this.settings,
    required this.style,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
