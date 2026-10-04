import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
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

export 'queue_manager_mixin.dart';

class AudioProvider with ChangeNotifier, QueueManagerMixin, LyricsManagerMixin, CrossfadeManagerMixin, PlaybackControlsMixin, PreferencesManagerMixin {
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
  int _playRequestId = 0;

  final YoutubeService _ytService = locator<YoutubeService>();
  SongModel? _currentSong;
  bool _isLoading = false;
  
  String? _playbackError;
  
  @override
  SongModel? get currentSong => _currentSong;
  
  @override
  set currentSongInternal(SongModel? song) => _currentSong = song;
  
  bool get isPlaying => player.playing;
  bool get isLoading => _isLoading || isFetchingAutoContinue;
  String? get playbackError => _playbackError;
  
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<dynamic> get visualizerStream => NativeVisualizerService.visualizerStream;
  int? get androidAudioSessionId => player.androidAudioSessionId;

  MusicAudioHandler? _audioHandler;
  Future<void>? _initFuture;

  AudioProvider() {
    _player1 = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer1]),
    );
    _player2 = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer2]),
    );

    _initSession();
    _initFuture = _initAudioService();
    initPrefs();
    
    _setupPlayer(_player1);
    _setupPlayer(_player2);
  }

  void _setupPlayer(AudioPlayer p) {
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
      onError: (Object e, StackTrace st) => _handlePlaybackStreamError(e, p),
    );

    p.positionStream.listen((pos) {
      if (player != p) return;
      final dur = p.duration;
      if (dur != null && _currentSong != null) {
        final remaining = dur - pos;
        if (remaining.inMilliseconds <= 3000 && remaining.inMilliseconds > 0) {
          if (!isCrossfading && hasNext && isCrossfadeEnabled) {
            startCrossfade(
              onPlayerChanged: (newPlayer) {
                _audioHandler?.updatePlayer(newPlayer);
              },
              playNextAction: () async {
                _isAutoChangingSong = true;
                await playNext(); // Await asynchronous loading of the next song
                _isAutoChangingSong = false;
              },
            );
          }
        }
      }
    });
  }

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MusicAudioHandler(player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_flow_mobile.channel.audio',
        androidNotificationChannelName: 'Music Flow',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_stat_music_note',
      ),
    );
    _audioHandler!.onPlay = resume;
    _audioHandler!.onSkipToNext = playNext;
    _audioHandler!.onSkipToPrevious = playPrevious;
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  Future<void> playSong(SongModel song) async {
    final int requestId = ++_playRequestId;

    if (!_isAutoChangingSong) {
      cancelCrossfade();
    }
    AppLogger.separator('PLAY');
    AppLogger.audio('Title : ${song.title}');
    AppLogger.audio('ID    : ${song.id}');
    AppLogger.audio('Local : ${song.isLocal} (Path: ${song.localPath})');
    
    _streamRetryCount = 0;
    _isLoading = true;
    _currentSong = song;
    resetLyricsState();
    _playbackError = null;
    
    // If we are playing a song not from the current queue, clear the queue
    if (isQueueMismatch(song)) {
       resetQueueWithSong(song);
    }

    notifyListeners();
    
    loadLyricsForSong(song, () => _currentSong);

    if (_initFuture != null) {
      await _initFuture;
    } else if (_audioHandler == null) {
      // In case of Hot Reload where constructor wasn't re-run
      _initFuture = _initAudioService();
      await _initFuture;
    }

    if (requestId != _playRequestId) return;

    try {
      final preparedSong = await PlaybackManager.preparePlayback(
        song: song,
        player: player,
        audioHandler: _audioHandler!,
        ytService: _ytService,
      );

      if (requestId != _playRequestId) return;

      _currentSong = preparedSong;
      updateCurrentSongInQueue(_currentSong!);
      
      // Log the successful play to the history database
      locator<DatabaseService>().logPlay(_currentSong!);
      
      // Initialize equalizer parameters if they failed to load at startup
      equalizerProvider.initIfNeeded();
      
    } catch (e, stacktrace) {
      if (requestId != _playRequestId) return;
      if (e.toString().contains('Loading interrupted')) {
        AppLogger.info('Завантаження треку було скасовано або перервано', 'AUDIO');
        return;
      }
      handleAudioPlaybackError(e, stacktrace, song, (msg) => _playbackError = msg);
    } finally {
      if (requestId == _playRequestId) {
        AppLogger.separator();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  int _streamRetryCount = 0;

  void _handlePlaybackStreamError(Object e, AudioPlayer p) async {
    if (player != p) return;
    final song = _currentSong;
    if (song != null && !song.isLocal && _streamRetryCount < 2) {
      _streamRetryCount++;
      AppLogger.warning('Playback stream error ($e). Auto-recovering URL...', 'AUDIO');
      await _refreshAndResume(song);
    } else {
      _streamRetryCount = 0;
      AppLogger.error('Playback stream error: $e', e, null, 'AUDIO');
    }
  }

  Future<void> _refreshAndResume(SongModel song) async {
    final int requestId = ++_playRequestId;
    final pos = player.position;
    _isLoading = true;
    notifyListeners();
    try {
      final preparedSong = await PlaybackManager.preparePlayback(
        song: song.copyWith(streamUrl: null),
        player: player,
        audioHandler: _audioHandler!,
        ytService: _ytService,
        initialPosition: pos,
      );
      if (requestId != _playRequestId) return;
      _currentSong = preparedSong;
      updateCurrentSongInQueue(_currentSong!);
      _streamRetryCount = 0;
    } catch (e, st) {
      if (requestId != _playRequestId) return;
      if (e.toString().contains('Loading interrupted')) {
        AppLogger.info('Оновлення потоку перервано іншим запитом', 'AUDIO');
        return;
      }
      handleAudioPlaybackError(e, st, song, (msg) => _playbackError = msg);
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
    if (song != null && !song.isLocal && song.streamUrl != null) {
      if (PlaybackManager.isYoutubeUrlExpired(song.streamUrl!)) {
        AppLogger.info('YouTube stream URL is expired upon resume. Refreshing...', 'AUDIO');
        await _refreshAndResume(song);
        return;
      }
    }

    try {
      await super.resume();
    } catch (e) {
      AppLogger.warning('Failed to resume ($e). Refreshing YouTube stream...', 'AUDIO');
      if (song != null && !song.isLocal) {
        await _refreshAndResume(song);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> stop() async {
    _playRequestId++;
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
