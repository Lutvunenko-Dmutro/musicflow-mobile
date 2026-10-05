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

  Timer? _fadePauseTimer;
  bool _isFadePausing = false;
  bool get isFadePausing => _isFadePausing;

  void cancelFadePause() {
    _fadePauseTimer?.cancel();
    _fadePauseTimer = null;
    _isFadePausing = false;
  }

  Future<void> smoothPause({Duration duration = const Duration(milliseconds: 700)}) async {
    if (!player.playing && !(isCrossfading && fadingPlayer.playing)) return;
    if (_isFadePausing) return;
    _fadePauseTimer?.cancel();
    _isFadePausing = true;

    final targetPlayer = player;
    final secondaryPlayer = isCrossfading ? fadingPlayer : null;
    final double startVolume = targetPlayer.volume > 0 ? targetPlayer.volume : 1.0;
    const int steps = 14;
    final int stepMs = duration.inMilliseconds ~/ steps;
    double currentVol = startVolume;

    _fadePauseTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) async {
      currentVol -= (startVolume / steps);
      if (currentVol <= 0.05 || !targetPlayer.playing) {
        timer.cancel();
        _fadePauseTimer = null;
        try {
          await targetPlayer.pause();
          if (secondaryPlayer != null) await secondaryPlayer.pause();
        } catch (_) {}
        try {
          await targetPlayer.setVolume(startVolume);
        } catch (_) {}
        _isFadePausing = false;
        notifyListeners();
      } else {
        try {
          await targetPlayer.setVolume(currentVol);
          if (secondaryPlayer != null) await secondaryPlayer.setVolume(currentVol);
        } catch (_) {}
      }
    });
  }

  Future<void> pause() async {
    cancelFadePause();
    await player.pause();
    if (isCrossfading) await fadingPlayer.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    cancelFadePause();
    try {
      await player.setVolume(1.0);
    } catch (_) {}
    await player.play();
    if (isCrossfading) await fadingPlayer.play();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> stop() async {
    cancelFadePause();
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
