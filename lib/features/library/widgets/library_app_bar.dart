import 'package:flutter/material.dart';
import '../screens/library_screen.dart' show SortOption;
import 'package:music_flow_mobile/l10n/app_strings.dart';

class LibraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final bool isSelectionMode;
  final bool isDescending;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onToggleSortDirection;
  final ValueChanged<SortOption> onSortSelected;
  final VoidCallback onRefresh;

  const LibraryAppBar({
    super.key,
    required this.selectedCount,
    required this.isSelectionMode,
    required this.isDescending,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onToggleSortDirection,
    required this.onSortSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return AppBar(
      title: Text(isSelectionMode ? '$selectedCount ${strings.selected}' : strings.library),
      leading: isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClearSelection,
            )
          : null,
      actions: [
        if (isSelectionMode)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: onDeleteSelected,
          )
        else ...[
          IconButton(
            icon: Icon(isDescending ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: strings.sortDirection,
            onPressed: onToggleSortDirection,
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: onSortSelected,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              PopupMenuItem<SortOption>(
                value: SortOption.title,
                child: Text(strings.sortByTitle),
              ),
              PopupMenuItem<SortOption>(
                value: SortOption.author,
                child: Text(strings.sortByArtist),
              ),
              PopupMenuItem<SortOption>(
                value: SortOption.dateAdded,
                child: Text(strings.sortByDate),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: strings.refresh,
            onPressed: onRefresh,
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
