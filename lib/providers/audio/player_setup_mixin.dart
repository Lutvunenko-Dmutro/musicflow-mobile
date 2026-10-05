import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/native_visualizer_service.dart';
import 'package:music_flow_mobile/services/audio_handler.dart';
import 'package:music_flow_mobile/providers/audio/crossfade_manager_mixin.dart';

mixin PlayerSetupMixin on CrossfadeManagerMixin {
  AudioPlayer get player;
  bool get hasNext;
  bool get isCrossfadeEnabled;
  bool get showVisualizer;
  SongModel? get currentSong;
  MusicAudioHandler? get audioHandler;

  void handleSongCompleted();
  void handlePlaybackStreamError(Object e, AudioPlayer p);
  Future<void> playNext();
  void setAutoChangingSong(bool value);

  void setupPlayerEvents(AudioPlayer p) {
    p.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (player == p && !isCrossfading) handleSongCompleted();
      }
      if (state.playing && state.processingState == ProcessingState.ready) {
        if (player == p) {
          if (showVisualizer) NativeVisualizerService.startVisualizer(p.androidAudioSessionId);
          startFadeInIfNeeded(p);
        }
      } else if (!state.playing || state.processingState == ProcessingState.completed) {
        if (player == p) NativeVisualizerService.stopVisualizer();
      }
      if (player == p) notifyListeners();
    });

    p.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) => handlePlaybackStreamError(e, p),
    );

    p.positionStream.listen((pos) {
      if (player != p) return;
      final dur = p.duration;
      if (dur != null && currentSong != null) {
        final remaining = dur - pos;
        if (remaining.inMilliseconds <= 3000 && remaining.inMilliseconds > 0) {
          if (!isCrossfading && hasNext && isCrossfadeEnabled) {
            startCrossfade(
              onPlayerChanged: (newPlayer) => audioHandler?.updatePlayer(newPlayer),
              playNextAction: () async {
                setAutoChangingSong(true);
                await playNext();
                setAutoChangingSong(false);
              },
            );
          }
        }
      }
    });
  }
}
