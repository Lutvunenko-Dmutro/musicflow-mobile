import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';

class VisualizerStylesGrid extends StatelessWidget {
  final VisualizerSettingsProvider settings;
  final VoidCallback onStyleChanged;

  const VisualizerStylesGrid({
    super.key,
    required this.settings,
    required this.onStyleChanged,
  });

  static const List<Map<String, dynamic>> styles = [
    {'style': VisualizerStyle.bars, 'title': 'Стовпчики', 'desc': 'Класичний еквалайзер', 'icon': Icons.equalizer},
    {'style': VisualizerStyle.mirrored, 'title': 'Дзеркало', 'desc': 'Симетрично від центру', 'icon': Icons.unfold_more},
    {'style': VisualizerStyle.circle, 'title': 'Коло', 'desc': 'Кругова діаграма', 'icon': Icons.donut_large},
    {'style': VisualizerStyle.wave, 'title': 'Хвиля', 'desc': 'Плавна звукова лінія', 'icon': Icons.waves},
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final item = styles[index];
        final style = item['style'] as VisualizerStyle;
        final isSelected = settings.style == style;

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
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primary : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['desc'] as String,
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
