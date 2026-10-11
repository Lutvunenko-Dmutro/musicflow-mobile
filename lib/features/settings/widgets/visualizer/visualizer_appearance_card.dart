import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class VisualizerAppearanceCard extends StatelessWidget {
  final VisualizerSettingsProvider settings;

  const VisualizerAppearanceCard({super.key, required this.settings});

  Widget _buildSegment<T>({
    required BuildContext context,
    required T value,
    required T groupValue,
    required String label,
    required IconData icon,
    required ValueChanged<T> onSelected,
  }) {
    final isSelected = value == groupValue;
    final primary = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primary : Colors.white10,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? primary : Colors.white60),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.visualizerAppearance,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 1. Placement (Bottom vs Cover Aura)
          Text(strings.visualizerPlacement, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSegment<VisualizerPosition>(
                context: context,
                value: VisualizerPosition.bottom,
                groupValue: settings.position,
                label: strings.visPosBottom,
                icon: Icons.border_bottom_rounded,
                onSelected: settings.setPosition,
              ),
              const SizedBox(width: 10),
              _buildSegment<VisualizerPosition>(
                context: context,
                value: VisualizerPosition.coverAura,
                groupValue: settings.position,
                label: strings.visPosCoverAura,
                icon: Icons.blur_on_rounded,
                onSelected: settings.setPosition,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Cover Shape (Square vs Vinyl)
          Text(strings.visCoverShape, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSegment<VisualizerCoverShape>(
                context: context,
                value: VisualizerCoverShape.roundedSquare,
                groupValue: settings.coverShape,
                label: strings.visShapeSquare,
                icon: Icons.crop_square_rounded,
                onSelected: settings.setCoverShape,
              ),
              const SizedBox(width: 10),
              _buildSegment<VisualizerCoverShape>(
                context: context,
                value: VisualizerCoverShape.circleVinyl,
                groupValue: settings.coverShape,
                label: strings.visShapeVinyl,
                icon: Icons.album_rounded,
                onSelected: settings.setCoverShape,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Color Theme
          Text(strings.visColorTheme, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSegment<VisualizerColorScheme>(
                context: context,
                value: VisualizerColorScheme.fire,
                groupValue: settings.colorScheme,
                label: strings.visColorFire,
                icon: Icons.local_fire_department_rounded,
                onSelected: settings.setColorScheme,
              ),
              const SizedBox(width: 8),
              _buildSegment<VisualizerColorScheme>(
                context: context,
                value: VisualizerColorScheme.adaptive,
                groupValue: settings.colorScheme,
                label: strings.visColorAdaptive,
                icon: Icons.auto_awesome_rounded,
                onSelected: settings.setColorScheme,
              ),
              const SizedBox(width: 8),
              _buildSegment<VisualizerColorScheme>(
                context: context,
                value: VisualizerColorScheme.cyberpunk,
                groupValue: settings.colorScheme,
                label: strings.visColorCyberpunk,
                icon: Icons.bolt_rounded,
                onSelected: settings.setColorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
