import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:music_flow_mobile/services/audio_handler.dart';

class AudioServiceInitializer {
  static Future<void> initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  static Future<MusicAudioHandler> initAudioService({
    required AudioPlayer player,
    required Future<void> Function() onPlay,
    required Future<void> Function() onSkipToNext,
    required Future<void> Function() onSkipToPrevious,
  }) async {
    final audioHandler = await AudioService.init(
      builder: () => MusicAudioHandler(player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_flow_mobile.channel.audio',
        androidNotificationChannelName: 'Music Flow',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    audioHandler.onPlay = onPlay;
    audioHandler.onSkipToNext = onSkipToNext;
    audioHandler.onSkipToPrevious = onSkipToPrevious;
    return audioHandler;
  }
}
