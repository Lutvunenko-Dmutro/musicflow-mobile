import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_segment_button.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class VisualizerAppearanceCard extends StatelessWidget {
  final VisualizerSettingsProvider settings;

  const VisualizerAppearanceCard({super.key, required this.settings});

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
              VisualizerSegmentButton<VisualizerPosition>(
                value: VisualizerPosition.bottom,
                groupValue: settings.position,
                label: strings.visPosBottom,
                icon: Icons.border_bottom_rounded,
                onSelected: settings.setPosition,
              ),
              const SizedBox(width: 10),
              VisualizerSegmentButton<VisualizerPosition>(
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
              VisualizerSegmentButton<VisualizerCoverShape>(
                value: VisualizerCoverShape.roundedSquare,
                groupValue: settings.coverShape,
                label: strings.visShapeSquare,
                icon: Icons.crop_square_rounded,
                onSelected: settings.setCoverShape,
              ),
              const SizedBox(width: 10),
              VisualizerSegmentButton<VisualizerCoverShape>(
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
              VisualizerSegmentButton<VisualizerColorScheme>(
                value: VisualizerColorScheme.fire,
                groupValue: settings.colorScheme,
                label: strings.visColorFire,
                icon: Icons.palette_rounded,
                onSelected: settings.setColorScheme,
              ),
              const SizedBox(width: 8),
              VisualizerSegmentButton<VisualizerColorScheme>(
                value: VisualizerColorScheme.adaptive,
                groupValue: settings.colorScheme,
                label: strings.visColorAdaptive,
                icon: Icons.auto_awesome_rounded,
                onSelected: settings.setColorScheme,
              ),
            ],
          ),

          if (settings.position == VisualizerPosition.coverAura) ...[
            const SizedBox(height: 18),
            Text(strings.visSpectrumMode, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              children: [
                VisualizerSegmentButton<AuraSpectrumMode>(
                  value: AuraSpectrumMode.live,
                  groupValue: settings.auraSpectrumMode,
                  label: strings.visSpectrumLive,
                  icon: Icons.graphic_eq_rounded,
                  onSelected: settings.setAuraSpectrumMode,
                ),
                const SizedBox(width: 8),
                VisualizerSegmentButton<AuraSpectrumMode>(
                  value: AuraSpectrumMode.mirrored4Side,
                  groupValue: settings.auraSpectrumMode,
                  label: strings.visSpectrumPulse4,
                  icon: Icons.flare_rounded,
                  onSelected: settings.setAuraSpectrumMode,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                VisualizerSegmentButton<AuraSpectrumMode>(
                  value: AuraSpectrumMode.mirrored2H,
                  groupValue: settings.auraSpectrumMode,
                  label: strings.visSpectrumMirror2H,
                  icon: Icons.swap_horiz_rounded,
                  onSelected: settings.setAuraSpectrumMode,
                ),
                const SizedBox(width: 8),
                VisualizerSegmentButton<AuraSpectrumMode>(
                  value: AuraSpectrumMode.mirrored2V,
                  groupValue: settings.auraSpectrumMode,
                  label: strings.visSpectrumMirror2V,
                  icon: Icons.swap_vert_rounded,
                  onSelected: settings.setAuraSpectrumMode,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
