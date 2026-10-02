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
import 'package:music_flow_mobile/services/lyrics_service.dart';
import 'package:music_flow_mobile/main.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';
import 'package:music_flow_mobile/providers/queue_manager_mixin.dart';

export 'queue_manager_mixin.dart';

class AudioProvider with ChangeNotifier, QueueManagerMixin {
  final AndroidEqualizer _equalizer1 = AndroidEqualizer();
  late final AudioPlayer _player1;

  final AndroidEqualizer _equalizer2 = AndroidEqualizer();
  late final AudioPlayer _player2;

  late final EqualizerProvider equalizerProvider = EqualizerProvider(
    equalizer1: _equalizer1,
    equalizer2: _equalizer2,
  );
  
  bool _usePlayer1 = true;
  
  bool _isCrossfading = false;
  bool _isAutoChangingSong = false;
  Timer? _crossfadeTimer;

  @override
  AudioPlayer get player => _usePlayer1 ? _player1 : _player2;
  AudioPlayer get _fadingPlayer => _usePlayer1 ? _player2 : _player1;

  final YoutubeService _ytService = locator<YoutubeService>();
  final LyricsService _lyricsService = LyricsService();
  SongModel? _currentSong;
  Map<String, String>? _availableLyrics;
  String? _selectedLyricsKey;
  bool _isLoading = false;
  bool _isLyricsLoading = false;
  String? _lyricsErrorMsg;
  // Player UI Settings
  bool _showVisualizer = true;
  bool get showVisualizer => _showVisualizer;

  bool _showInlineLyrics = true;
  bool get showInlineLyrics => _showInlineLyrics;

  String? _playbackError;
  
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  SongModel? get currentSong => _currentSong;
  Map<String, String>? get availableLyrics => _availableLyrics;
  String? get selectedLyricsKey => _selectedLyricsKey;
  String? get currentLyrics => _selectedLyricsKey != null && _availableLyrics != null ? _availableLyrics![_selectedLyricsKey!] : null;
  bool get isPlaying => player.playing;
  bool get isLoading => _isLoading;
  bool get isLyricsLoading => _isLyricsLoading;
  String? get lyricsErrorMsg => _lyricsErrorMsg;
  String? get playbackError => _playbackError;
  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;
  
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
    
    _setupPlayer(_player1);
    _setupPlayer(_player2);
  }

  void _setupPlayer(AudioPlayer p) {
    p.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (player == p && !_isCrossfading) handleSongCompleted();
      }
      if (state.playing && state.processingState == ProcessingState.ready) {
        if (player == p) NativeVisualizerService.startVisualizer(p.androidAudioSessionId);
      } else if (!state.playing || state.processingState == ProcessingState.completed) {
        if (player == p) NativeVisualizerService.stopVisualizer();
      }
      if (player == p) notifyListeners();
    });

    p.positionStream.listen((pos) {
      if (player != p) return;
      final dur = p.duration;
      if (dur != null && _currentSong != null) {
        final remaining = dur - pos;
        if (remaining.inMilliseconds <= 3000 && remaining.inMilliseconds > 0) {
          if (!_isCrossfading && hasNext) {
            _startCrossfade();
          }
        }
      }
    });
  }

  void _startCrossfade() {
    if (_isCrossfading) return;
    _isCrossfading = true;

    final oldPlayer = player;
    _usePlayer1 = !_usePlayer1;
    final newPlayer = player;
    
    _audioHandler?.updatePlayer(newPlayer);
    
    _crossfadeTimer?.cancel();
    int steps = 30; // 3 seconds
    int durationMs = 3000;
    int stepDuration = durationMs ~/ steps;
    
    double oldVol = 1.0;
    double newVol = 0.0;
    newPlayer.setVolume(0.0);
    
    _isAutoChangingSong = true;
    playNext(); // This will load the next song into the new player
    _isAutoChangingSong = false;
    
    _crossfadeTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
      oldVol -= (1.0 / steps);
      newVol += (1.0 / steps);
      
      if (oldVol <= 0.0 || newVol >= 1.0) {
        oldPlayer.setVolume(0.0);
        oldPlayer.stop();
        newPlayer.setVolume(1.0);
        _isCrossfading = false;
        timer.cancel();
      } else {
        oldPlayer.setVolume(oldVol);
        newPlayer.setVolume(newVol);
      }
    });
    
    notifyListeners();
  }

  void _cancelCrossfade() {
    if (_isCrossfading) {
      _crossfadeTimer?.cancel();
      _isCrossfading = false;
      _fadingPlayer.stop();
      player.setVolume(1.0);
    }
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
    _audioHandler!.onSkipToNext = playNext;
    _audioHandler!.onSkipToPrevious = playPrevious;
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  Future<void> playSong(SongModel song) async {
    if (!_isAutoChangingSong) {
      _cancelCrossfade();
    }
    AppLogger.separator('PLAY');
    AppLogger.audio('Title : ${song.title}');
    AppLogger.audio('ID    : ${song.id}');
    AppLogger.audio('Local : ${song.isLocal} (Path: ${song.localPath})');
    
    _isLoading = true;
    _isLyricsLoading = true;
    _currentSong = song;
    _availableLyrics = null;
    _selectedLyricsKey = null;
    _lyricsErrorMsg = null;
    _playbackError = null;
    
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
    }).catchError((e) {
      if (_currentSong?.id == song.id) {
        _isLyricsLoading = false;
        if (e.toString().contains('SocketException')) {
          _lyricsErrorMsg = 'Немає підключення до інтернету.';
        } else {
          _lyricsErrorMsg = 'Помилка завантаження тексту.';
        }
        notifyListeners();
      }
    }).catchError((e) {
      if (_currentSong?.id == song.id) {
        _isLyricsLoading = false;
        if (e.toString().contains('SocketException')) {
          _lyricsErrorMsg = 'Немає підключення до інтернету.';
        } else {
          _lyricsErrorMsg = 'Помилка завантаження тексту.';
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
        player: player,
        audioHandler: _audioHandler!,
        ytService: _ytService,
      );
      
      // Log the successful play to the history database
      locator<DatabaseService>().logPlay(_currentSong!);
      
      // Initialize equalizer parameters if they failed to load at startup
      equalizerProvider.initIfNeeded();
      
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
      } else if (errorMsg.contains('SocketException') || errorMsg.contains('Failed host lookup')) {
        _playbackError = 'Немає підключення до інтернету.';
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(_playbackError!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _playbackError = 'Помилка: $errorMsg';
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(_playbackError!),
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
    await player.pause();
    if (_isCrossfading) await _fadingPlayer.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await player.play();
    if (_isCrossfading) await _fadingPlayer.play();
    notifyListeners();
  }

  void changeLyricsTrack(String key) {
    if (_availableLyrics != null && _availableLyrics!.containsKey(key)) {
      _selectedLyricsKey = key;
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> stop() async {
    await player.stop();
    if (_isCrossfading) await _fadingPlayer.stop();
    _cancelCrossfade();
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

  void toggleVisualizer() {
    _showVisualizer = !_showVisualizer;
    notifyListeners();
  }

  void toggleInlineLyrics() {
    _showInlineLyrics = !_showInlineLyrics;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _crossfadeTimer?.cancel();
    _player1.dispose();
    _player2.dispose();
    super.dispose();
  }
}
