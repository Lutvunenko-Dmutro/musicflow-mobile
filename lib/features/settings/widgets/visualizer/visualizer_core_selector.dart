import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
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
    final l10n = context.l10n;
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
              title: l10n.visCoreSoftwareTitle,
              subtitle: l10n.visCoreSoftwareDesc,
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
              title: l10n.visCoreHardwareTitle,
              subtitle: l10n.visCoreHardwareDesc,
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? primary : Colors.white70,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white60 : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
