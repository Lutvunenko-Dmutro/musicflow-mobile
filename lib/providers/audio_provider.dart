import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import '../models/song_model.dart';
import '../services/youtube_service.dart';
import '../utils/app_logger.dart';

enum RepeatMode { off, all, one }

class AudioProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _ytService = YoutubeService();
  static const MethodChannel _methodChannel = MethodChannel('com.example.music_flow_mobile/visualizer_method');
  static const EventChannel _eventChannel = EventChannel('com.example.music_flow_mobile/visualizer_event');
  StreamSubscription? _visualizerSubscription;

  SongModel? _currentSong;
  bool _isLoading = false;
  List<SongModel> _queue = [];
  int _currentIndex = -1;
  
  bool _isShuffleModeEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  SongModel? get currentSong => _currentSong;
  bool get hasNext => _queue.isNotEmpty && (_currentIndex < _queue.length - 1 || _repeatMode == RepeatMode.all || _isShuffleModeEnabled);
  bool get hasPrevious => _queue.isNotEmpty && (_currentIndex > 0 || _repeatMode == RepeatMode.all || _isShuffleModeEnabled);
  bool get isPlaying => _player.playing;
  bool get isLoading => _isLoading;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  RepeatMode get repeatMode => _repeatMode;
  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;
  
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<dynamic> get visualizerStream => _eventChannel.receiveBroadcastStream();
  int? get androidAudioSessionId => _player.androidAudioSessionId;

  AudioProvider() {
    _initSession();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
      if (state.playing && state.processingState == ProcessingState.ready) {
        _startNativeVisualizer();
      } else if (!state.playing || state.processingState == ProcessingState.completed) {
        _stopNativeVisualizer();
      }
      notifyListeners();
    });
  }

  Future<void> _startNativeVisualizer() async {
    final sessionId = _player.androidAudioSessionId;
    if (sessionId != null && sessionId != 0) {
      try {
        await _methodChannel.invokeMethod('startVisualizer', {'sessionId': sessionId});
      } catch (e) {
        AppLogger.error('Error starting native visualizer', e, null, 'AUDIO');
      }
    }
  }

  Future<void> _stopNativeVisualizer() async {
    try {
      await _methodChannel.invokeMethod('stopVisualizer');
    } catch (e) {
      AppLogger.error('Error stopping native visualizer', e, null, 'AUDIO');
    }
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  void setQueue(List<SongModel> queue, {int initialIndex = 0}) {
    _queue = queue;
    _currentIndex = initialIndex;
    if (_queue.isNotEmpty) {
      playSong(_queue[_currentIndex]);
    }
  }

  Future<void> playSong(SongModel song) async {
    AppLogger.separator('PLAY');
    AppLogger.audio('Title : ${song.title}');
    AppLogger.audio('ID    : ${song.id}');
    AppLogger.audio('Local : ${song.isLocal} (Path: ${song.localPath})');
    
    _isLoading = true;
    _currentSong = song;
    
    // If we are playing a song not from the current queue, clear the queue
    if (_queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length || _queue[_currentIndex].id != song.id) {
       _queue = [song];
       _currentIndex = 0;
    }

    notifyListeners();

    try {
      if (song.isLocal && song.localPath != null) {
        AppLogger.audio('Source: Local Storage');
        final duration = await _player.setAudioSource(AudioSource.file(song.localPath!));
        if (duration != null) {
          _currentSong = _currentSong?.copyWith(duration: duration);
        }
        AppLogger.success('Playing directly from device.', 'AUDIO');
        _player.play();
      } else {
        AppLogger.audio('Source: Internet (YouTube)');
        String? audioUrl = song.streamUrl;
        
        if (audioUrl == null) {
          AppLogger.info('Fetching stream URL from YoutubeService...', 'AUDIO');
          audioUrl = await _ytService.getAudioStreamUrl(song.id);
          AppLogger.success('Stream URL fetched.', 'AUDIO');
          _currentSong = song.copyWith(streamUrl: audioUrl);
        }

        if (audioUrl != null) {
          AppLogger.info('Connecting to just_audio...', 'AUDIO');
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(audioUrl),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
              },
            ),
          );
          AppLogger.success('Playing from internet stream.', 'AUDIO');
          _player.play();
        } else {
          AppLogger.error('Failed to fetch audioUrl!', null, null, 'AUDIO');
        }
      }
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

  void _onSongCompleted() {
    if (_repeatMode == RepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
      return;
    }
    playNext();
  }

  void playNext() {
    if (_queue.isEmpty) return;
    
    if (_isShuffleModeEnabled && _queue.length > 1) {
      int nextIndex;
      do {
        nextIndex = Random().nextInt(_queue.length);
      } while (nextIndex == _currentIndex);
      _currentIndex = nextIndex;
      playSong(_queue[_currentIndex]);
    } else {
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
        playSong(_queue[_currentIndex]);
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
        playSong(_queue[_currentIndex]);
      } else {
        _player.stop();
        _player.seek(Duration.zero);
      }
    }
  }

  void playPrevious() {
    if (_queue.isEmpty) return;
    
    if (_player.position.inSeconds > 3) {
      _player.seek(Duration.zero);
      return;
    }

    if (_isShuffleModeEnabled && _queue.length > 1) {
      int prevIndex;
      do {
        prevIndex = Random().nextInt(_queue.length);
      } while (prevIndex == _currentIndex);
      _currentIndex = prevIndex;
      playSong(_queue[_currentIndex]);
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
        playSong(_queue[_currentIndex]);
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _queue.length - 1;
        playSong(_queue[_currentIndex]);
      } else {
        _player.seek(Duration.zero);
      }
    }
  }

  void toggleShuffle() {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    notifyListeners();
  }

  void toggleRepeat() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.all;
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
    } else {
      _repeatMode = RepeatMode.off;
    }
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
