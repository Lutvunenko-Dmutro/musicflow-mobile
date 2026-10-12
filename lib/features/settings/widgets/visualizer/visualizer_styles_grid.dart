import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

class VisualizerStylesGrid extends StatelessWidget {
  final VisualizerSettingsProvider settings;
  final VoidCallback onStyleChanged;

  const VisualizerStylesGrid({
    super.key,
    required this.settings,
    required this.onStyleChanged,
  });

  static const List<Map<String, dynamic>> _styleItems = [
    {'style': VisualizerStyle.bars, 'icon': Icons.equalizer},
    {'style': VisualizerStyle.mirrored, 'icon': Icons.unfold_more},
    {'style': VisualizerStyle.circle, 'icon': Icons.donut_large},
    {'style': VisualizerStyle.wave, 'icon': Icons.waves},
  ];

  (String, String) _getStyleLabels(VisualizerStyle style, AppStrings l10n) {
    switch (style) {
      case VisualizerStyle.bars:
        return (l10n.visStyleBars, l10n.visStyleBarsDesc);
      case VisualizerStyle.mirrored:
        return (l10n.visStyleMirrored, l10n.visStyleMirroredDesc);
      case VisualizerStyle.circle:
        return (l10n.visStyleCircle, l10n.visStyleCircleDesc);
      case VisualizerStyle.wave:
        return (l10n.visStyleWave, l10n.visStyleWaveDesc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final l10n = context.l10n;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: _styleItems.length,
      itemBuilder: (context, index) {
        final item = _styleItems[index];
        final style = item['style'] as VisualizerStyle;
        final isSelected = settings.style == style;
        final (title, desc) = _getStyleLabels(style, l10n);

        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            settings.setStyle(style);
            onStyleChanged();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? primary.withValues(alpha: 0.15) : const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primary : Colors.white10,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, color: isSelected ? primary : Colors.white70, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primary : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
