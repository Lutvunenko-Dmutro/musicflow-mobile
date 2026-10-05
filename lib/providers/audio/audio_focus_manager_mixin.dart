import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

mixin AudioFocusManagerMixin on ChangeNotifier {
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;

  bool get smoothMediaPause;
  AudioPlayer get player;
  Future<void> smoothPause({Duration duration = const Duration(milliseconds: 700)});
  Future<void> pause();

  Future<void> initAudioFocus() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _interruptionSub?.cancel();
    _interruptionSub = session.interruptionEventStream.listen((event) {
      AppLogger.audio('🎧 Зміна аудіофокусу: begin=${event.begin}, type=${event.type}');
      if (event.begin) {
        if (!player.playing) return;
        if (smoothMediaPause) {
          smoothPause(duration: const Duration(milliseconds: 700));
        } else {
          pause();
        }
      }
    });

    _becomingNoisySub?.cancel();
    _becomingNoisySub = session.becomingNoisyEventStream.listen((_) {
      AppLogger.audio('🎧 Навушники відключено (becoming noisy)');
      if (!player.playing) return;
      if (smoothMediaPause) {
        smoothPause(duration: const Duration(milliseconds: 500));
      } else {
        pause();
      }
    });
  }

  Future<void> activateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (e) {
      AppLogger.audio('Помилка активації AudioSession: $e');
    }
  }

  void disposeAudioFocus() {
    _interruptionSub?.cancel();
    _becomingNoisySub?.cancel();
  }
}
