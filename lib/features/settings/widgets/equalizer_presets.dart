import 'package:flutter/material.dart';

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
          const Text(
            'Рекомендовані пресети',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = preset == activePreset;
              return GestureDetector(
                onTap: () => onPresetSelected(preset),
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive ? Theme.of(context).primaryColor : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? const Color(0x4DFFFFFF) : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    preset,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[300],
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
