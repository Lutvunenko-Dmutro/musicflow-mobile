import 'package:flutter/material.dart';
import '../screens/library_screen.dart' show SortOption;

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
    return AppBar(
      title: Text(isSelectionMode ? '$selectedCount вибрано' : 'Бібліотека'),
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
            tooltip: 'Змінити напрямок',
            onPressed: onToggleSortDirection,
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: onSortSelected,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.title,
                child: Text('За назвою'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.author,
                child: Text('За автором'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.dateAdded,
                child: Text('За часом додавання'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
