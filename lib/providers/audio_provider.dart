import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/youtube_service.dart';
import '../services/native_visualizer_service.dart';
import '../services/playback_manager.dart';
import '../utils/app_logger.dart';
import 'queue_manager_mixin.dart';

export 'queue_manager_mixin.dart';

class AudioProvider with ChangeNotifier, QueueManagerMixin {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _ytService = YoutubeService();
  SongModel? _currentSong;
  bool _isLoading = false;
  
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _player.playing;
  bool get isLoading => _isLoading;
  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;
  
  @override
  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<dynamic> get visualizerStream => NativeVisualizerService.visualizerStream;
  int? get androidAudioSessionId => _player.androidAudioSessionId;

  MusicAudioHandler? _audioHandler;
  Future<void>? _initFuture;

  AudioProvider() {
    _initSession();
    _initFuture = _initAudioService();
    
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        handleSongCompleted();
      }
      if (state.playing && state.processingState == ProcessingState.ready) {
        NativeVisualizerService.startVisualizer(_player.androidAudioSessionId);
      } else if (!state.playing || state.processingState == ProcessingState.completed) {
        NativeVisualizerService.stopVisualizer();
      }
      notifyListeners();
    });
  }

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MusicAudioHandler(_player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_flow_mobile.channel.audio',
        androidNotificationChannelName: 'Music Flow',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_stat_music_note',
      ),
    );
    _audioHandler!.onSkipToNext = playNext;
    _audioHandler!.onSkipToPrevious = playPrevious;
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  Future<void> playSong(SongModel song) async {
    AppLogger.separator('PLAY');
    AppLogger.audio('Title : ${song.title}');
    AppLogger.audio('ID    : ${song.id}');
    AppLogger.audio('Local : ${song.isLocal} (Path: ${song.localPath})');
    
    _isLoading = true;
    _currentSong = song;
    
    // If we are playing a song not from the current queue, clear the queue
    if (isQueueMismatch(song)) {
       resetQueueWithSong(song);
    }

    notifyListeners();
    
    if (_initFuture != null) {
      await _initFuture;
    } else if (_audioHandler == null) {
      // In case of Hot Reload where constructor wasn't re-run
      _initFuture = _initAudioService();
      await _initFuture;
    }

    try {
      _currentSong = await PlaybackManager.preparePlayback(
        song: song,
        player: _player,
        audioHandler: _audioHandler!,
        ytService: _ytService,
      );
    } catch (e, stacktrace) {
      AppLogger.error('Exception while playing', e, stacktrace, 'AUDIO');
    } finally {
      AppLogger.separator();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSong = null;
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerEndTime = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      pause();
      _sleepTimerEndTime = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    _ytService.dispose();
    super.dispose();
  }
}
