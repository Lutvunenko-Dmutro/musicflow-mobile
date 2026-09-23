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
import '../locator.dart';
import '../services/database_service.dart';
import '../services/lyrics_service.dart';
import '../main.dart';
import 'queue_manager_mixin.dart';

export 'queue_manager_mixin.dart';

class AudioProvider with ChangeNotifier, QueueManagerMixin {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _ytService = locator<YoutubeService>();
  final LyricsService _lyricsService = LyricsService();
  SongModel? _currentSong;
  Map<String, String>? _availableLyrics;
  String? _selectedLyricsKey;
  bool _isLoading = false;
  bool _isLyricsLoading = false;
  
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  SongModel? get currentSong => _currentSong;
  Map<String, String>? get availableLyrics => _availableLyrics;
  String? get selectedLyricsKey => _selectedLyricsKey;
  String? get currentLyrics => _selectedLyricsKey != null && _availableLyrics != null ? _availableLyrics![_selectedLyricsKey!] : null;
  bool get isPlaying => _player.playing;
  bool get isLoading => _isLoading;
  bool get isLyricsLoading => _isLyricsLoading;
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
    _isLyricsLoading = true;
    _currentSong = song;
    _availableLyrics = null;
    _selectedLyricsKey = null;
    
    // If we are playing a song not from the current queue, clear the queue
    if (isQueueMismatch(song)) {
       resetQueueWithSong(song);
    }

    notifyListeners();
    
    _lyricsService.getLyrics(
      song,
      onUpdate: (freshLyrics) {
        if (_currentSong?.id == song.id) {
          _availableLyrics = freshLyrics;
          if (_selectedLyricsKey == null || !freshLyrics.containsKey(_selectedLyricsKey)) {
            _selectedLyricsKey = freshLyrics.keys.first;
          }
          notifyListeners();
        }
      },
    ).then((lyricsMap) {
      if (_currentSong?.id == song.id) {
        _isLyricsLoading = false;
        if (lyricsMap != null && lyricsMap.isNotEmpty) {
          _availableLyrics = lyricsMap;
          if (_selectedLyricsKey == null || !lyricsMap.containsKey(_selectedLyricsKey)) {
            _selectedLyricsKey = lyricsMap.keys.first;
          }
        }
        notifyListeners();
      }
    });

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
      
      // Log the successful play to the history database
      locator<DatabaseService>().logPlay(_currentSong!);
      
    } catch (e, stacktrace) {
      AppLogger.error('Exception while playing', e, stacktrace, 'AUDIO');
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      if (errorMsg.contains('Локальний файл не знайдено')) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          showDialog(
            context: ctx,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Файл відсутній'),
              content: const Text('Цей аудіофайл було видалено з пристрою. Бажаєте видалити цей запис з історії?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Ні', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    locator<DatabaseService>().removeFromHistory(song.id);
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('Видалити', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        }
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  void changeLyricsTrack(String key) {
    if (_availableLyrics != null && _availableLyrics!.containsKey(key)) {
      _selectedLyricsKey = key;
      notifyListeners();
    }
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
    super.dispose();
  }
}
