import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/models/song_model.dart';

enum RepeatMode { off, all, one }

mixin QueueManagerMixin on ChangeNotifier {
  List<SongModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleModeEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isPlayingNext = true;

  bool get hasNext => _queue.isNotEmpty && (_currentIndex < _queue.length - 1 || _repeatMode == RepeatMode.all || _isShuffleModeEnabled);
  bool get hasPrevious => _queue.isNotEmpty && (_currentIndex > 0 || _repeatMode == RepeatMode.all || _isShuffleModeEnabled);
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  RepeatMode get repeatMode => _repeatMode;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlayingNext => _isPlayingNext;
  
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

  void handleSongCompleted() {
    if (_repeatMode == RepeatMode.one) {
      player.seek(Duration.zero);
      player.play();
      return;
    }
    playNext();
  }

  void playNext() {
    _isPlayingNext = true;
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
        player.stop();
        player.seek(Duration.zero);
      }
    }
  }

  void playPrevious() {
    _isPlayingNext = false;
    if (_queue.isEmpty) return;
    
    if (player.position.inSeconds > 3) {
      player.seek(Duration.zero);
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
        player.seek(Duration.zero);
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
