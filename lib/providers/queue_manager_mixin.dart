import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

enum RepeatMode { off, all, one }

mixin QueueManagerMixin on ChangeNotifier {
  List<SongModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleModeEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isPlayingNext = true;
  bool _isFetchingAutoContinue = false;

  bool get hasNext => true; // Always has next due to auto-continue
  bool get hasPrevious => _queue.isNotEmpty && (_currentIndex > 0 || _repeatMode == RepeatMode.all || _isShuffleModeEnabled);
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  RepeatMode get repeatMode => _repeatMode;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlayingNext => _isPlayingNext;
  bool get isFetchingAutoContinue => _isFetchingAutoContinue;
  
  // These must be implemented by the class mixing this in
  AudioPlayer get player;
  Future<void> playSong(SongModel song);

  void setQueue(List<SongModel> queue, {int initialIndex = 0}) {
    _queue = queue;
    _currentIndex = initialIndex;
    if (_queue.isNotEmpty) {
      playSong(_queue[_currentIndex]);
    }
  }
  
  bool isQueueMismatch(SongModel song) {
    return _queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length || _queue[_currentIndex].id != song.id;
  }
  
  void resetQueueWithSong(SongModel song) {
    _queue = [song];
    _currentIndex = 0;
  }

  void updateCurrentSongInQueue(SongModel updatedSong) {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _queue[_currentIndex] = updatedSong;
    }
  }

  void handleSongCompleted() {
    if (_repeatMode == RepeatMode.one) {
      player.seek(Duration.zero);
      player.play();
      return;
    }
    playNext();
  }

  Future<void> playNext() async {
    _isPlayingNext = true;
    if (_queue.isEmpty) return;
    
    if (_isShuffleModeEnabled && _queue.length > 1) {
      int nextIndex;
      do {
        nextIndex = Random().nextInt(_queue.length);
      } while (nextIndex == _currentIndex);
      _currentIndex = nextIndex;
      await playSong(_queue[_currentIndex]);
    } else {
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
        await playSong(_queue[_currentIndex]);
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
        await playSong(_queue[_currentIndex]);
      } else {
        await _triggerAutoContinue();
      }
    }
  }

  Future<void> _triggerAutoContinue() async {
    if (_isFetchingAutoContinue) return;
    if (_queue.isEmpty || _currentIndex < 0) return;

    _isFetchingAutoContinue = true;
    notifyListeners();

    try {
      final ytService = locator<YoutubeService>();
      final currentSong = _queue[_currentIndex];
      
      AppLogger.info('Triggering auto-continue for author: ${currentSong.author}', 'QUEUE');
      
      final results = await ytService.searchSongs(currentSong.author);
      
      final queueIds = _queue.map((s) => s.id).toSet();
      final newSongs = results.where((s) => !queueIds.contains(s.id)).toList();
      
      if (newSongs.isNotEmpty) {
        _queue.addAll(newSongs);
        _currentIndex++;
        await playSong(_queue[_currentIndex]);
      } else {
        // Fallback to stop if nothing found
        player.stop();
        player.seek(Duration.zero);
      }
    } catch (e) {
      AppLogger.error('Failed auto-continue', e, null, 'QUEUE');
      player.stop();
      player.seek(Duration.zero);
    } finally {
      _isFetchingAutoContinue = false;
      notifyListeners();
    }
  }

  Future<void> playPrevious() async {
    _isPlayingNext = false;
    if (_queue.isEmpty) return;
    
    if (player.position.inSeconds > 3) {
      await player.seek(Duration.zero);
      return;
    }

    if (_isShuffleModeEnabled && _queue.length > 1) {
      int prevIndex;
      do {
        prevIndex = Random().nextInt(_queue.length);
      } while (prevIndex == _currentIndex);
      _currentIndex = prevIndex;
      await playSong(_queue[_currentIndex]);
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
        await playSong(_queue[_currentIndex]);
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _queue.length - 1;
        await playSong(_queue[_currentIndex]);
      } else {
        await player.seek(Duration.zero);
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

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final SongModel item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      // If we removed the currently playing song
      if (_queue.isEmpty) {
        _currentIndex = -1;
        player.stop();
      } else {
        if (_currentIndex >= _queue.length) {
          _currentIndex = 0;
        }
        playSong(_queue[_currentIndex]);
      }
    }
    notifyListeners();
  }
}
