import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

mixin CrossfadeManagerMixin on ChangeNotifier {
  bool _usePlayer1 = true;
  bool _needsFadeIn = false;
  Timer? _fadeOutTimer;
  Timer? _fadeInTimer;
  bool _isFadingOut = false;
  bool _isFadingIn = false;

  AudioPlayer get player1;
  AudioPlayer get player2;

  AudioPlayer get currentPlayer => _usePlayer1 ? player1 : player2;
  AudioPlayer get fadingPlayer => _usePlayer1 ? player2 : player1;
  
  bool get isCrossfading => _isFadingOut || _isFadingIn;

  void startCrossfade({
    required Function(AudioPlayer) onPlayerChanged,
    required Function() playNextAction,
  }) {
    if (_isFadingOut) return;
    
    debugPrint('🎵 [CROSSFADE] startCrossfade triggered!');
    final oldPlayer = currentPlayer;
    _usePlayer1 = !_usePlayer1;
    final newPlayer = currentPlayer;
    
    onPlayerChanged(newPlayer);
    
    // Start fading out the old player
    _fadeOutTimer?.cancel();
    _isFadingOut = true;
    
    int steps = 30; // 3 seconds
    int stepDuration = 3000 ~/ steps;
    double oldVol = 1.0;
    
    _fadeOutTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
      oldVol -= (1.0 / steps);
      if (oldVol <= 0.0) {
        oldPlayer.setVolume(0.0);
        oldPlayer.stop();
        _isFadingOut = false;
        timer.cancel();
      } else {
        oldPlayer.setVolume(oldVol);
      }
    });

    // Make sure new player starts at 0 volume so it can fade in later
    newPlayer.setVolume(0.0);
    _needsFadeIn = true;
    debugPrint('🎵 [CROSSFADE] Set new player volume to 0.0, _needsFadeIn = true');
    
    // This will trigger the asynchronous loading of the next song.
    // We shouldn't start fading it in until it actually starts playing!
    playNextAction();
  }

  void startFadeInIfNeeded(AudioPlayer p) {
    debugPrint('🎵 [CROSSFADE] startFadeInIfNeeded called. _needsFadeIn: $_needsFadeIn, isCurrent: ${currentPlayer == p}');
    if (!_needsFadeIn || currentPlayer != p) return;
    _needsFadeIn = false;
    
    debugPrint('🎵 [CROSSFADE] Starting fade-in timer!');
    _fadeInTimer?.cancel();
    _isFadingIn = true;
    
    final newPlayer = currentPlayer;
    int steps = 30;
    int stepDuration = 3000 ~/ steps;
    double newVol = 0.0;
    
    _fadeInTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
      newVol += (1.0 / steps);
      if (newVol >= 1.0) {
        newPlayer.setVolume(1.0);
        _isFadingIn = false;
        debugPrint('🎵 [CROSSFADE] Fade in complete!');
        timer.cancel();
      } else {
        newPlayer.setVolume(newVol);
      }
    });
  }

  void cancelCrossfade() {
    debugPrint('🎵 [CROSSFADE] cancelCrossfade called!');
    _fadeOutTimer?.cancel();
    _fadeInTimer?.cancel();
    _isFadingOut = false;
    _isFadingIn = false;
    _needsFadeIn = false;
    fadingPlayer.stop();
    currentPlayer.setVolume(1.0);
  }

  void disposeCrossfade() {
    _fadeOutTimer?.cancel();
    _fadeInTimer?.cancel();
  }
}
