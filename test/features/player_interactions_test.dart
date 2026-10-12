import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/animated_mode_button.dart';
import 'package:music_flow_mobile/features/player/widgets/player_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSong = SongModel(
    id: 'test_1',
    title: 'Test Track',
    author: 'Test Artist',
    duration: const Duration(seconds: 180),
    coverUrl: 'https://example.com/cover.jpg',
  );

  group('AnimatedModeButton Tests', () {
    testWidgets('AnimatedShuffleButton toggles and animates without TweenSequence error', (tester) async {
      bool active = false;
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => AnimatedShuffleButton(
                  isActive: active,
                  onTap: () {
                    tapCount++;
                    setState(() => active = !active);
                  },
                  primary: Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedShuffleButton), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);

      await tester.tap(find.byType(AnimatedShuffleButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(tapCount, equals(1));
      expect(active, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AnimatedRepeatButton cycles modes and animates without TweenSequence overshoot', (tester) async {
      var mode = AudioRepeatMode.off;
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => AnimatedRepeatButton(
                  repeatMode: mode,
                  onTap: () {
                    tapCount++;
                    setState(() {
                      mode = mode == AudioRepeatMode.off
                          ? AudioRepeatMode.all
                          : (mode == AudioRepeatMode.all ? AudioRepeatMode.one : AudioRepeatMode.off);
                    });
                  },
                  primary: Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedRepeatButton), findsOneWidget);

      // Tap 1: off -> all
      await tester.tap(find.byType(AnimatedRepeatButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(mode, equals(AudioRepeatMode.all));
      expect(tester.takeException(), isNull);

      // Tap 2: all -> one
      await tester.tap(find.byType(AnimatedRepeatButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(mode, equals(AudioRepeatMode.one));
      expect(tester.takeException(), isNull);

      // Tap 3: one -> off
      await tester.tap(find.byType(AnimatedRepeatButton));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(mode, equals(AudioRepeatMode.off));
      expect(tapCount, equals(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('PlayerHeader Gestures Tests', () {
    testWidgets('PlayerHeader renders and handles horizontal swipes smoothly', (tester) async {
      final mockAudio = _MockAudioProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AudioProvider>.value(
              value: mockAudio,
              child: SizedBox(
                width: 400,
                height: 500,
                child: PlayerHeader(song: testSong),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test Track'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      // Drag left (towards next track)
      await tester.drag(find.byType(PlayerHeader), const Offset(-120, 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(mockAudio.nextCalled, isTrue);
      expect(tester.takeException(), isNull);

      // Drag right (towards previous track)
      await tester.drag(find.byType(PlayerHeader), const Offset(120, 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(mockAudio.prevCalled, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockAudioProvider extends ChangeNotifier implements AudioProvider {
  bool nextCalled = false;
  bool prevCalled = false;

  @override
  bool get isPlaying => false;

  @override
  bool get hasNext => true;

  @override
  bool get hasPrevious => true;

  @override
  Future<void> playNext() async {
    nextCalled = true;
    notifyListeners();
  }

  @override
  Future<void> playPrevious() async {
    prevCalled = true;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
