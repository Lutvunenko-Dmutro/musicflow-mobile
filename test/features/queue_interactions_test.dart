import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/screens/queue_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final song1 = SongModel(id: 'q1', title: 'Queue Song 1', author: 'Artist 1', duration: const Duration(seconds: 180), coverUrl: '');
  final song2 = SongModel(id: 'q2', title: 'Queue Song 2', author: 'Artist 2', duration: const Duration(seconds: 240), coverUrl: '');
  final song3 = SongModel(id: 'q3', title: 'Queue Song 3', author: 'Artist 3', duration: const Duration(seconds: 210), coverUrl: '');

  group('QueueScreen Interactions Tests', () {
    testWidgets('Tapping song in queue triggers setQueue with selected index', (tester) async {
      final mock = _MockQueueAudioProvider([song1, song2, song3]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AudioProvider>.value(
            value: mock,
            child: const QueueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Queue Song 2'), findsOneWidget);

      await tester.tap(find.text('Queue Song 2'));
      await tester.pumpAndSettle();

      expect(mock.playedIndex, equals(1));
    });

    testWidgets('Swiping song in queue dismisses and removes it', (tester) async {
      final mock = _MockQueueAudioProvider([song1, song2, song3]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AudioProvider>.value(
            value: mock,
            child: const QueueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final firstItemFinder = find.byKey(const ValueKey('q1_0'));
      expect(firstItemFinder, findsOneWidget);

      // Swipe right to left (endToStart)
      await tester.drag(firstItemFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(mock.removedIndex, equals(0));
    });
  });
}

class _MockQueueAudioProvider extends ChangeNotifier implements AudioProvider {
  final List<SongModel> _queue;
  int _currentIndex = 0;
  int? playedIndex;
  int? removedIndex;

  _MockQueueAudioProvider(this._queue);

  @override
  List<SongModel> get queue => _queue;

  @override
  int get currentIndex => _currentIndex;

  @override
  void setQueue(List<SongModel> queue, {int initialIndex = 0}) {
    playedIndex = initialIndex;
    _currentIndex = initialIndex;
    notifyListeners();
  }

  void playTrackAt(int index) {
    playedIndex = index;
    _currentIndex = index;
    notifyListeners();
  }

  @override
  void removeFromQueue(int index) {
    removedIndex = index;
    _queue.removeAt(index);
    notifyListeners();
  }

  @override
  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
