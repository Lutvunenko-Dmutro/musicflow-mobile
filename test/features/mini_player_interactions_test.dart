import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/core/animations/animated_play_pause.dart';
import 'package:music_flow_mobile/features/player/widgets/mini_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSong = SongModel(
    id: 'mini_test_1',
    title: 'Mini Track',
    author: 'Mini Artist',
    duration: const Duration(seconds: 180),
    coverUrl: '',
  );

  group('MiniPlayer Gesture & Control Tests', () {
    testWidgets('Renders nothing when no song is active', (tester) async {
      final mock = _MockMiniAudioProvider(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AudioProvider>.value(
              value: mock,
              child: const MiniPlayer(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Mini Track'), findsNothing);
    });

    testWidgets('Tapping play/pause button in MiniPlayer toggles playback', (tester) async {
      final mock = _MockMiniAudioProvider(testSong);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AudioProvider>.value(
              value: mock,
              child: const MiniPlayer(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Mini Track'), findsOneWidget);
      expect(find.text('Mini Artist'), findsOneWidget);

      final playPauseIcon = find.byType(AnimatedPlayPauseIcon);
      expect(playPauseIcon, findsOneWidget);

      await tester.tap(playPauseIcon);
      await tester.pump();
      expect(mock.resumeCalled || mock.pauseCalled, isTrue);
    });
  });
}

class _MockMiniAudioProvider extends ChangeNotifier implements AudioProvider {
  final SongModel? _currentSong;
  bool resumeCalled = false;
  bool pauseCalled = false;

  _MockMiniAudioProvider(this._currentSong);

  @override
  SongModel? get currentSong => _currentSong;

  @override
  bool get isPlaying => false;

  @override
  bool get isLoading => false;

  @override
  bool get hasNext => false;

  @override
  bool get hasPrevious => false;

  @override
  Stream<Duration> get positionStream => Stream.value(const Duration(seconds: 5));

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
