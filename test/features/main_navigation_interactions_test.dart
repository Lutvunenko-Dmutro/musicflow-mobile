import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Main NavigationBar Interactions', () {
    testWidgets('Tapping destinations updates selectedIndex and switches tabs', (tester) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: Text('Tab index: $currentIndex'),
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) {
                    if (currentIndex != index) {
                      setState(() => currentIndex = index);
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: 'Пошук',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music),
                      label: 'Медіатека',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: 'Історія',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Налаштування',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tab index: 0'), findsOneWidget);

      // Tap 'Медіатека' (Index 1)
      await tester.tap(find.text('Медіатека'));
      await tester.pumpAndSettle();
      expect(find.text('Tab index: 1'), findsOneWidget);

      // Tap 'Історія' (Index 2)
      await tester.tap(find.text('Історія'));
      await tester.pumpAndSettle();
      expect(find.text('Tab index: 2'), findsOneWidget);

      // Tap 'Налаштування' (Index 3)
      await tester.tap(find.text('Налаштування'));
      await tester.pumpAndSettle();
      expect(find.text('Tab index: 3'), findsOneWidget);

      // Tap 'Пошук' back (Index 0)
      await tester.tap(find.text('Пошук'));
      await tester.pumpAndSettle();
      expect(find.text('Tab index: 0'), findsOneWidget);
    });
  });
}
