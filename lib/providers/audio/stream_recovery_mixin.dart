import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/audio_handler.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/services/playback_manager.dart';
import 'package:music_flow_mobile/utils/audio_error_handler.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

mixin StreamRecoveryMixin on ChangeNotifier {
  AudioPlayer get player;
  MusicAudioHandler? get audioHandler;
  YoutubeService get ytService;
  SongModel? get currentSong;
  set currentSongInternal(SongModel? song);
  void updateCurrentSongInQueue(SongModel song);
  void setIsLoading(bool loading);
  void setPlaybackError(String? error);
  int get playRequestId;
  int incrementPlayRequestId();

  int _streamRetryCount = 0;
  int get streamRetryCount => _streamRetryCount;
  void resetStreamRetryCount() => _streamRetryCount = 0;

  void handlePlaybackStreamError(Object e, AudioPlayer p) async {
    if (player != p) return;
    final song = currentSong;
    if (song != null && !song.isLocal && _streamRetryCount < 2) {
      _streamRetryCount++;
      AppLogger.warning('Playback stream error ($e). Auto-recovering URL...', 'AUDIO');
      await refreshAndResume(song);
    } else {
      _streamRetryCount = 0;
      AppLogger.error('Playback stream error: $e', e, null, 'AUDIO');
    }
  }

  Future<void> refreshAndResume(SongModel song) async {
    final int requestId = incrementPlayRequestId();
    final pos = player.position;
    setIsLoading(true);
    notifyListeners();
    try {
      final preparedSong = await PlaybackManager.preparePlayback(
        song: song.copyWith(streamUrl: null),
        player: player,
        audioHandler: audioHandler!,
        ytService: ytService,
        initialPosition: pos,
      );
      if (requestId != playRequestId) return;
      currentSongInternal = preparedSong;
      updateCurrentSongInQueue(currentSong!);
      _streamRetryCount = 0;
    } catch (e, st) {
      if (requestId != playRequestId) return;
      if (e.toString().contains('Loading interrupted')) {
        AppLogger.info('Оновлення потоку перервано іншим запитом', 'AUDIO');
        return;
      }
      handleAudioPlaybackError(e, st, song, (msg) => setPlaybackError(msg));
    } finally {
      if (requestId == playRequestId) {
        setIsLoading(false);
        notifyListeners();
      }
    }
  }
}
