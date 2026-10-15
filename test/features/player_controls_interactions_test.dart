import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/core/animations/animated_play_pause.dart';
import 'package:music_flow_mobile/features/player/widgets/player_controls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSong = SongModel(
    id: 'ctrl_test_1',
    title: 'Interaction Track',
    author: 'Interaction Artist',
    duration: const Duration(seconds: 200),
    coverUrl: '',
  );

  group('PlayerControls Gesture & Tap Interactions', () {
    testWidgets('Tapping Play/Pause triggers resume/pause on AudioProvider', (tester) async {
      final mock = _MockAudioProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AudioProvider>.value(
              value: mock,
              child: PlayerControls(song: testSong),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final playPauseIcon = find.byType(AnimatedPlayPauseIcon);
      expect(playPauseIcon, findsOneWidget);

      await tester.tap(playPauseIcon);
      await tester.pump();
      expect(mock.resumeCalled || mock.pauseCalled, isTrue);
    });

    testWidgets('Tapping Next and Previous triggers navigation', (tester) async {
      final mock = _MockAudioProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AudioProvider>.value(
              value: mock,
              child: PlayerControls(song: testSong),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nextBtn = find.byIcon(Icons.skip_next_rounded);
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pump();
      expect(mock.nextCalled, isTrue);

      final prevBtn = find.byIcon(Icons.skip_previous_rounded);
      expect(prevBtn, findsOneWidget);
      await tester.tap(prevBtn);
      await tester.pump();
      expect(mock.prevCalled, isTrue);
    });

    testWidgets('Dragging progress Slider triggers seek to new position', (tester) async {
      final mock = _MockAudioProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AudioProvider>.value(
              value: mock,
              child: PlayerControls(song: testSong),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      await tester.drag(sliderFinder, const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(mock.seekCalled, isTrue);
      expect(mock.seekedPosition.inMilliseconds, greaterThan(0));
    });
  });
}

class _MockAudioProvider extends ChangeNotifier implements AudioProvider {
  bool resumeCalled = false;
  bool pauseCalled = false;
  bool nextCalled = false;
  bool prevCalled = false;
  bool seekCalled = false;
  Duration seekedPosition = Duration.zero;

  @override
  bool get isPlaying => false;

  @override
  bool get isLoading => false;

  @override
  bool get hasNext => true;

  @override
  bool get hasPrevious => true;

  @override
  bool get isShuffleModeEnabled => false;

  @override
  AudioRepeatMode get repeatMode => AudioRepeatMode.off;

  @override
  Stream<Duration> get positionStream => Stream.value(const Duration(seconds: 10));

  @override
  Future<void> resume() async {
    resumeCalled = true;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    notifyListeners();
  }

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
  Future<void> seek(Duration position) async {
    seekCalled = true;
    seekedPosition = position;
    notifyListeners();
  }

  @override
  void toggleShuffle() {
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
