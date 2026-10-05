import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/core/widgets/custom_card.dart';
import 'package:music_flow_mobile/models/search_filter_model.dart';

class SearchInputCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final SearchFilterModel filter;
  final VoidCallback onOpenFilter;
  final bool isSearching;

  const SearchInputCard({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.filter,
    required this.onOpenFilter,
    this.isSearching = false,
  });

  Widget _buildActiveBadge(String text, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return CustomCard(
      child: Column(
        children: [
          const Text(
            'Пошук треків або посилання з YouTube',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
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
                    suffixIcon: isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
                          )
                        : (controller.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 18, color: Colors.white54), onPressed: () => controller.clear())
                            : null),
                    hintText: 'Введіть назву або посилання...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: isSearching
                    ? null
                    : () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final text = data?.text?.trim() ?? '';
                        if (text.isNotEmpty) {
                          controller.text = text;
                          onSearch();
                        }
                      },
                icon: isSearching
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                    : const Icon(Icons.content_paste_rounded, size: 16),
                label: Text(isSearching ? 'Пошук...' : 'Вставити', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          if (isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: Icon(Icons.tune_rounded, size: 16, color: filter.activeFiltersCount > 0 ? primary : Colors.grey[400]),
                  label: Text(
                    filter.activeFiltersCount > 0 ? 'Фільтри (${filter.activeFiltersCount})' : 'Фільтр',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: filter.activeFiltersCount > 0 ? FontWeight.bold : FontWeight.normal,
                      color: filter.activeFiltersCount > 0 ? primary : Colors.white70,
                    ),
                  ),
                  backgroundColor: filter.activeFiltersCount > 0 ? primary.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
                  side: BorderSide(color: filter.activeFiltersCount > 0 ? primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onPressed: onOpenFilter,
                ),
                if (filter.region != 'all') ...[
                  const SizedBox(width: 8),
                  _buildActiveBadge(filter.region == 'ua' ? '🇺🇦 UA' : filter.region.toUpperCase(), primary),
                ],
                if (filter.genre != 'all') ...[
                  const SizedBox(width: 8),
                  _buildActiveBadge(filter.genre, primary),
                ],
                if (filter.format != 'all') ...[
                  const SizedBox(width: 8),
                  _buildActiveBadge(filter.format, primary),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Icon(Icons.graphic_eq_rounded, size: 56, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          const Text('Що послухаємо сьогодні?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'Знайдіть пісню за назвою чи автором або вставте пряме посилання на трек, відео чи плейліст з YouTube.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}
