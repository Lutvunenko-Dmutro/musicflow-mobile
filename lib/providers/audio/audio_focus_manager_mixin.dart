import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

mixin AudioFocusManagerMixin on ChangeNotifier {
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  StreamSubscription<bool>? _playingSub1;
  StreamSubscription<bool>? _playingSub2;

  bool get smoothMediaPause;
  AudioPlayer get player;
  AudioPlayer get player1;
  AudioPlayer get player2;
  Future<void> smoothPause({Duration duration = const Duration(milliseconds: 1200)});
  Future<void> pause();

  Future<void> initAudioFocus() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _interruptionSub?.cancel();
    _interruptionSub = session.interruptionEventStream.listen((event) {
      AppLogger.audio('🎧 Зміна аудіофокусу: begin=${event.begin}, type=${event.type}');
      if (event.begin) {
        if (!player.playing) return;
        AppLogger.audio('🎧 Виявлено інше медіа (TikTok/YouTube), плавна зупинка...');
        if (smoothMediaPause) {
          smoothPause(duration: const Duration(milliseconds: 1200));
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
        smoothPause(duration: const Duration(milliseconds: 600));
      } else {
        pause();
      }
    });

    _setupPlayingListeners();
  }

  void _setupPlayingListeners() {
    _playingSub1?.cancel();
    _playingSub1 = player1.playingStream.listen((playing) {
      if (playing) {
        activateAudioSession();
      } else if (!player2.playing) {
        deactivateAudioSession();
      }
    });

    _playingSub2?.cancel();
    _playingSub2 = player2.playingStream.listen((playing) {
      if (playing) {
        activateAudioSession();
      } else if (!player1.playing) {
        deactivateAudioSession();
      }
    });
  }

  Future<bool> activateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      final success = await session.setActive(
        true,
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidWillPauseWhenDucked: true,
      );
      AppLogger.audio('🎧 AudioSession фокус захоплено: success=$success');
      return success;
    } catch (e) {
      AppLogger.audio('Помилка активації AudioSession: $e');
      return false;
    }
  }

  Future<void> deactivateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
      AppLogger.audio('🎧 AudioSession фокус звільнено');
    } catch (e) {
      AppLogger.audio('Помилка деактивації AudioSession: $e');
    }
  }

  void disposeAudioFocus() {
    _interruptionSub?.cancel();
    _becomingNoisySub?.cancel();
    _playingSub1?.cancel();
    _playingSub2?.cancel();
  }
}
