import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';

class SearchInputCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool musicOnly;
  final ValueChanged<bool> onMusicOnlyChanged;

  const SearchInputCard({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.musicOnly,
    required this.onMusicOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return CustomCard(
      child: Column(
        children: [
          const Text(
            'Пошук треків або посилання з YouTube',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60, size: 22),
                    hintText: 'Введіть назву або посилання...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                  if (clipboardData != null && clipboardData.text != null) {
                    final text = clipboardData.text!.trim();
                    if (text.isNotEmpty) {
                      controller.text = text;
                      onSearch();
                    }
                  }
                },
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('Вставити', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                label: const Text('Тільки музика', style: TextStyle(fontSize: 12)),
                avatar: Icon(
                  Icons.music_note_rounded,
                  size: 15,
                  color: musicOnly ? primary : Colors.grey[400],
                ),
                selected: musicOnly,
                selectedColor: primary.withValues(alpha: 0.2),
                checkmarkColor: primary,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: musicOnly ? primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                onSelected: onMusicOnlyChanged,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Icon(
            Icons.graphic_eq_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),
          const Text(
            'Що послухаємо сьогодні?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Знайдіть пісню за назвою чи автором або вставте пряме посилання на трек, відео чи плейліст з YouTube.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
