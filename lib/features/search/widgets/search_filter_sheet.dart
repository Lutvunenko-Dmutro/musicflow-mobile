import 'package:flutter/material.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/models/search_filter_model.dart';

class SearchFilterSheet extends StatefulWidget {
  final SearchFilterModel initialFilter;
  final ValueChanged<SearchFilterModel> onApply;

  const SearchFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required SearchFilterModel filter,
    required ValueChanged<SearchFilterModel> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SearchFilterSheet(
        initialFilter: filter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilterModel _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: primary.withValues(alpha: 0.25),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: BorderSide(
        color: isSelected ? primary : Colors.white.withValues(alpha: 0.1),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[400],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final l10n = context.l10n;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(l10n.filterSheetTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _filter = const SearchFilterModel()),
                child: Text(l10n.resetFilters, style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(l10n.contentFormatHeader),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _buildChip(label: l10n.formatAll, isSelected: _filter.format == 'all', onTap: () => setState(() => _filter = _filter.copyWith(format: 'all'))),
                    _buildChip(label: l10n.formatStudio, isSelected: _filter.format == 'studio', onTap: () => setState(() => _filter = _filter.copyWith(format: 'studio'))),
                    _buildChip(label: l10n.formatClip, isSelected: _filter.format == 'clip', onTap: () => setState(() => _filter = _filter.copyWith(format: 'clip'))),
                    _buildChip(label: l10n.formatLive, isSelected: _filter.format == 'live', onTap: () => setState(() => _filter = _filter.copyWith(format: 'live'))),
                    _buildChip(label: l10n.formatAcoustic, isSelected: _filter.format == 'acoustic', onTap: () => setState(() => _filter = _filter.copyWith(format: 'acoustic'))),
                    _buildChip(label: l10n.formatRemix, isSelected: _filter.format == 'remix', onTap: () => setState(() => _filter = _filter.copyWith(format: 'remix'))),
                  ]),
                  _buildSectionTitle(l10n.countryLanguageHeader),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _buildChip(label: l10n.regionAll, isSelected: _filter.region == 'all', onTap: () => setState(() => _filter = _filter.copyWith(region: 'all'))),
                    _buildChip(label: l10n.regionUa, isSelected: _filter.region == 'ua', onTap: () => setState(() => _filter = _filter.copyWith(region: 'ua'))),
                    _buildChip(label: l10n.regionGlobal, isSelected: _filter.region == 'global', onTap: () => setState(() => _filter = _filter.copyWith(region: 'global'))),
                    _buildChip(label: l10n.regionRu, isSelected: _filter.region == 'ru', onTap: () => setState(() => _filter = _filter.copyWith(region: 'ru'))),
                    _buildChip(label: l10n.regionKpop, isSelected: _filter.region == 'kpop', onTap: () => setState(() => _filter = _filter.copyWith(region: 'kpop'))),
                    _buildChip(label: l10n.regionLatino, isSelected: _filter.region == 'latino', onTap: () => setState(() => _filter = _filter.copyWith(region: 'latino'))),
                  ]),
                  _buildSectionTitle(l10n.genreHeader),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _buildChip(label: l10n.genreAll, isSelected: _filter.genre == 'all', onTap: () => setState(() => _filter = _filter.copyWith(genre: 'all'))),
                    _buildChip(label: l10n.genreRock, isSelected: _filter.genre == 'rock', onTap: () => setState(() => _filter = _filter.copyWith(genre: 'rock'))),
                    _buildChip(label: l10n.genrePop, isSelected: _filter.genre == 'pop', onTap: () => setState(() => _filter = _filter.copyWith(genre: 'pop'))),
                    _buildChip(label: l10n.genreElectronic, isSelected: _filter.genre == 'electronic', onTap: () => setState(() => _filter = _filter.copyWith(genre: 'electronic'))),
                    _buildChip(label: l10n.genreRap, isSelected: _filter.genre == 'rap', onTap: () => setState(() => _filter = _filter.copyWith(genre: 'rap'))),
                    _buildChip(label: l10n.genreLofi, isSelected: _filter.genre == 'lofi', onTap: () => setState(() => _filter = _filter.copyWith(genre: 'lofi'))),
                  ]),
                  _buildSectionTitle(l10n.durationHeader),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _buildChip(label: l10n.durationAny, isSelected: _filter.durationFilter == SearchDurationFilter.any, onTap: () => setState(() => _filter = _filter.copyWith(durationFilter: SearchDurationFilter.any))),
                    _buildChip(label: l10n.durationUnder5, isSelected: _filter.durationFilter == SearchDurationFilter.under5Min, onTap: () => setState(() => _filter = _filter.copyWith(durationFilter: SearchDurationFilter.under5Min))),
                    _buildChip(label: l10n.durationUnder10, isSelected: _filter.durationFilter == SearchDurationFilter.under10Min, onTap: () => setState(() => _filter = _filter.copyWith(durationFilter: SearchDurationFilter.under10Min))),
                    _buildChip(label: l10n.durationOver10, isSelected: _filter.durationFilter == SearchDurationFilter.over10Min, onTap: () => setState(() => _filter = _filter.copyWith(durationFilter: SearchDurationFilter.over10Min))),
                  ]),
                  _buildSectionTitle(l10n.sortHeader),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _buildChip(label: l10n.sortRelevance, isSelected: _filter.sortBy == SearchSortBy.relevance, onTap: () => setState(() => _filter = _filter.copyWith(sortBy: SearchSortBy.relevance))),
                    _buildChip(label: l10n.sortViews, isSelected: _filter.sortBy == SearchSortBy.views, onTap: () => setState(() => _filter = _filter.copyWith(sortBy: SearchSortBy.views))),
                    _buildChip(label: l10n.sortNewest, isSelected: _filter.sortBy == SearchSortBy.newest, onTap: () => setState(() => _filter = _filter.copyWith(sortBy: SearchSortBy.newest))),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_filter);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.applyFilters, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
