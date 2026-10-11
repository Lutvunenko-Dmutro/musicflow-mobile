import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EqualizerPresetsWidget extends StatelessWidget {
  final String activePreset;
  final ValueChanged<String> onPresetSelected;

  const EqualizerPresetsWidget({
    super.key,
    required this.activePreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final presets = [
      'Звичайний', 'Рок', 'Поп',
      'Джаз', 'Класика', 'Хіп-хоп',
      'Метал', 'Танцювальна', 'Акустика',
      'Вокал', 'Bass Boost', 'Налаштувати',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              const Text(
                'Рекомендовані пресети',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = preset == activePreset;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPresetSelected(preset);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isActive ? primary : const Color(0xFF222226),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? Colors.white.withValues(alpha: 0.6) : Colors.white12,
                        width: isActive ? 1.5 : 1.0,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            preset,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
