import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/sleep_timer_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SleepTimerDialog Interactions', () {
    testWidgets('Tapping a preset minute option sets sleep timer and pops dialog', (tester) async {
      final mock = _MockTimerAudioProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SleepTimerDialog(provider: mock),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(SleepTimerDialog), findsOneWidget);

      // Tap 30 minutes option
      final option30 = find.textContaining('30');
      expect(option30, findsOneWidget);
      await tester.tap(option30);
      await tester.pumpAndSettle();

      expect(mock.setTimerDuration, equals(const Duration(minutes: 30)));
      expect(find.byType(SleepTimerDialog), findsNothing);
    });

    testWidgets('Shows cancel button when timer is active and cancels timer on tap', (tester) async {
      final mock = _MockTimerAudioProvider();
      mock.sleepTimerEndTime = DateTime.now().add(const Duration(minutes: 15));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SleepTimerDialog(provider: mock),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final cancelTile = find.byWidgetPredicate(
        (w) => w is ListTile && w.title is Text && (w.title as Text).data!.contains('Вимкнути'),
      );
      expect(cancelTile, findsOneWidget);

      await tester.tap(cancelTile);
      await tester.pumpAndSettle();

      expect(mock.timerCancelled, isTrue);
      expect(find.byType(SleepTimerDialog), findsNothing);
    });
  });
}

class _MockTimerAudioProvider extends ChangeNotifier implements AudioProvider {
  Duration? setTimerDuration;
  bool timerCancelled = false;

  @override
  DateTime? sleepTimerEndTime;

  @override
  void setSleepTimer(Duration duration) {
    setTimerDuration = duration;
    sleepTimerEndTime = DateTime.now().add(duration);
    notifyListeners();
  }

  @override
  void cancelSleepTimer() {
    timerCancelled = true;
    sleepTimerEndTime = null;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
