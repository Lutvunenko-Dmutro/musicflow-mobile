import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/audio_handler.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/services/native_visualizer_service.dart';
import 'package:music_flow_mobile/services/playback_manager.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/utils/audio_error_handler.dart';
import 'package:music_flow_mobile/providers/lyrics_manager_mixin.dart';
import 'package:music_flow_mobile/providers/crossfade_manager_mixin.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';
import 'package:music_flow_mobile/providers/queue_manager_mixin.dart';
import 'package:music_flow_mobile/providers/playback_controls_mixin.dart';
import 'package:music_flow_mobile/providers/preferences_manager_mixin.dart';
import 'package:music_flow_mobile/providers/stream_recovery_mixin.dart';
import 'package:music_flow_mobile/providers/audio_service_initializer.dart';
import 'package:music_flow_mobile/providers/player_setup_mixin.dart';

export 'queue_manager_mixin.dart';

class AudioProvider with ChangeNotifier, QueueManagerMixin, LyricsManagerMixin, CrossfadeManagerMixin, PlaybackControlsMixin, PreferencesManagerMixin, StreamRecoveryMixin, PlayerSetupMixin {
  final AndroidEqualizer _equalizer1 = AndroidEqualizer();
  late final AudioPlayer _player1;
  final AndroidEqualizer _equalizer2 = AndroidEqualizer();
  late final AudioPlayer _player2;

  late final EqualizerProvider equalizerProvider = EqualizerProvider(
    equalizer1: _equalizer1,
    equalizer2: _equalizer2,
  );
  
  @override
  AudioPlayer get player1 => _player1;
  @override
  AudioPlayer get player2 => _player2;
  @override
  AudioPlayer get player => currentPlayer;

  bool _isAutoChangingSong = false;
  @override
  void setAutoChangingSong(bool value) => _isAutoChangingSong = value;

  int _playRequestId = 0;
  @override
  int get playRequestId => _playRequestId;
  @override
  int incrementPlayRequestId() => ++_playRequestId;

  @override
  final YoutubeService ytService = locator<YoutubeService>();
  SongModel? _currentSong;
  bool _isLoading = false;
  String? _playbackError;
  
  @override
  SongModel? get currentSong => _currentSong;
  @override
  set currentSongInternal(SongModel? song) => _currentSong = song;
  @override
  void setIsLoading(bool loading) => _isLoading = loading;
  @override
  void setPlaybackError(String? error) => _playbackError = error;
  
  bool get isPlaying => player.playing;
  bool get isLoading => _isLoading || isFetchingAutoContinue;
  String? get playbackError => _playbackError;
  
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<dynamic> get visualizerStream => NativeVisualizerService.visualizerStream;
  int? get androidAudioSessionId => player.androidAudioSessionId;

  MusicAudioHandler? _audioHandler;
  @override
  MusicAudioHandler? get audioHandler => _audioHandler;
  Future<void>? _initFuture;

  AudioProvider() {
    _player1 = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer1]));
    _player2 = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer2]));

    AudioServiceInitializer.initSession();
    _initFuture = _startAudioService();
    initPrefs();
    
    setupPlayerEvents(_player1);
    setupPlayerEvents(_player2);
  }

  Future<void> _startAudioService() async {
    _audioHandler = await AudioServiceInitializer.initAudioService(
      player: player,
      onPlay: resume,
      onSkipToNext: playNext,
      onSkipToPrevious: playPrevious,
    );
  }

  @override
  Future<void> playSong(SongModel song) async {
    final int requestId = incrementPlayRequestId();
    if (!_isAutoChangingSong) cancelCrossfade();
    AppLogger.audio('Playing: ${song.title} (${song.id})');
    
    resetStreamRetryCount();
    _isLoading = true;
    _currentSong = song;
    resetLyricsState();
    _playbackError = null;
    
    if (isQueueMismatch(song)) resetQueueWithSong(song);
    notifyListeners();
    loadLyricsForSong(song, () => _currentSong);

    if (_initFuture != null) {
      await _initFuture;
    } else if (_audioHandler == null) {
      _initFuture = _startAudioService();
      await _initFuture;
    }

    if (requestId != _playRequestId) return;

    try {
      final preparedSong = await PlaybackManager.preparePlayback(
        song: song,
        player: player,
        audioHandler: _audioHandler!,
        ytService: ytService,
      );

      if (requestId != _playRequestId) return;
      _currentSong = preparedSong;
      updateCurrentSongInQueue(_currentSong!);
      locator<DatabaseService>().logPlay(_currentSong!);
      equalizerProvider.initIfNeeded();
    } catch (e, stacktrace) {
      if (requestId != _playRequestId || e.toString().contains('Loading interrupted')) return;
      handleAudioPlaybackError(e, stacktrace, song, (msg) => _playbackError = msg);
    } finally {
      if (requestId == _playRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  Future<void> resume() async {
    final song = _currentSong;
    if (song != null && !song.isLocal && song.streamUrl != null && PlaybackManager.isYoutubeUrlExpired(song.streamUrl!)) {
      AppLogger.info('YouTube stream URL is expired upon resume. Refreshing...', 'AUDIO');
      return refreshAndResume(song);
    }
    try {
      await super.resume();
    } catch (e) {
      if (song != null && !song.isLocal) return refreshAndResume(song);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    incrementPlayRequestId();
    await super.stop();
  }

  @override
  void dispose() {
    disposeSleepTimer();
    disposeCrossfade();
    _player1.dispose();
    _player2.dispose();
    super.dispose();
  }
}
