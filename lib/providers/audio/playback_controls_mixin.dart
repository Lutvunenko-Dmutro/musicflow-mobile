import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio/crossfade_manager_mixin.dart';

mixin PlaybackControlsMixin on ChangeNotifier, CrossfadeManagerMixin {
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  // Must be implemented by the class mixing this in
  AudioPlayer get player;
  SongModel? get currentSong;

  // State setters that must be implemented
  set currentSongInternal(SongModel? song);

  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;

  Future<void> pause() async {
    await player.pause();
    if (isCrossfading) await fadingPlayer.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await player.play();
    if (isCrossfading) await fadingPlayer.play();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> stop() async {
    await player.stop();
    if (isCrossfading) await fadingPlayer.stop();
    cancelCrossfade();
    currentSongInternal = null;
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

  void disposeSleepTimer() {
    _sleepTimer?.cancel();
  }
}
