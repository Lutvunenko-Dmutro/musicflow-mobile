import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/audio_handler.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/services/playback_art_helper.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class PlaybackManager {
  static Future<void> ensureDefaultArtPrepared() =>
      PlaybackArtHelper.ensureDefaultArtPrepared();

  static bool isYoutubeUrlExpired(String url) {
    try {
      final uri = Uri.parse(url);
      final expireStr = uri.queryParameters['expire'];
      if (expireStr == null) return false;
      final expireUnix = int.tryParse(expireStr);
      if (expireUnix == null) return false;
      final expireTime = DateTime.fromMillisecondsSinceEpoch(expireUnix * 1000);
      return DateTime.now().isAfter(expireTime.subtract(const Duration(minutes: 5)));
    } catch (_) {
      return false;
    }
  }

  static Future<Duration?> _setPlayerUri(
    AudioPlayer player,
    String url,
    Duration? initialPosition,
  ) {
    return player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
      ),
      initialPosition: initialPosition,
    );
  }

  static Future<SongModel> preparePlayback({
    required SongModel song,
    required AudioPlayer player,
    required MusicAudioHandler audioHandler,
    required YoutubeService ytService,
    Duration? initialPosition,
  }) async {
    await PlaybackArtHelper.ensureDefaultArtPrepared();
    final prefs = await SharedPreferences.getInstance();
    final showNotification = prefs.getBool('show_media_notification') ?? true;

    if (showNotification && await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    SongModel updatedSong = song;
    bool playLocally = song.isLocal && song.localPath != null;

    if (playLocally) {
      if (!File(song.localPath!).existsSync()) {
        if (song.id.length == 11 && !song.id.contains('/')) {
          AppLogger.warning('Local file not found, falling back to internet stream.', 'AUDIO');
          playLocally = false;
          updatedSong = updatedSong.copyWith(isLocal: false, localPath: null);
        } else {
          throw Exception('Локальний файл не знайдено, а потокове відтворення неможливе.');
        }
      }
    }

    if (playLocally) {
      return _playLocal(
        song: updatedSong,
        player: player,
        audioHandler: audioHandler,
        showNotification: showNotification,
        initialPosition: initialPosition,
      );
    } else {
      return _playOnline(
        song: updatedSong,
        player: player,
        audioHandler: audioHandler,
        ytService: ytService,
        showNotification: showNotification,
        initialPosition: initialPosition,
      );
    }
  }

  static Future<SongModel> _playLocal({
    required SongModel song,
    required AudioPlayer player,
    required MusicAudioHandler audioHandler,
    required bool showNotification,
    Duration? initialPosition,
  }) async {
    AppLogger.audio('Source: Local Storage');
    final duration = await player.setAudioSource(
      AudioSource.file(song.localPath!),
      initialPosition: initialPosition,
    );

    final localArtUri = await PlaybackArtHelper.resolveArtUriForLocal(song);

    if (showNotification) {
      await audioHandler.updateMediaItem(MediaItem(
        id: song.id,
        album: "Local Storage",
        title: song.title,
        artist: song.author,
        artUri: localArtUri,
        duration: duration ?? song.duration,
      ));
    }
    SongModel updated = song;
    if (duration != null) {
      updated = updated.copyWith(duration: duration);
    }
    AppLogger.success('Playing directly from device.', 'AUDIO');
    player.play();
    return updated;
  }

  static Future<SongModel> _playOnline({
    required SongModel song,
    required AudioPlayer player,
    required MusicAudioHandler audioHandler,
    required YoutubeService ytService,
    required bool showNotification,
    Duration? initialPosition,
  }) async {
    AppLogger.audio('Source: Internet (YouTube)');
    String? audioUrl = song.streamUrl;
    SongModel updated = song;

    if (audioUrl == null || isYoutubeUrlExpired(audioUrl)) {
      AppLogger.info('Fetching fresh stream URL from YoutubeService...', 'AUDIO');
      audioUrl = await ytService.getAudioStreamUrl(song.id);
      AppLogger.success('Stream URL fetched.', 'AUDIO');
      updated = updated.copyWith(streamUrl: audioUrl);
    }

    if (audioUrl == null) {
      AppLogger.error('Failed to fetch audioUrl!', null, null, 'AUDIO');
      throw Exception('Ця пісня недоступна для відтворення (обмеження YouTube).');
    }

    AppLogger.info('Connecting to just_audio...', 'AUDIO');
    final artUri = await PlaybackArtHelper.resolveArtUriForOnline(song);

    Duration? duration;
    try {
      duration = await _setPlayerUri(player, audioUrl, initialPosition);
    } catch (e) {
      if (e.toString().contains('Loading interrupted')) rethrow;
      AppLogger.warning('Stream error ($e), attempting refresh with new YouTube URL...', 'AUDIO');
      audioUrl = await ytService.getAudioStreamUrl(song.id);
      if (audioUrl == null) rethrow;
      updated = updated.copyWith(streamUrl: audioUrl);
      duration = await _setPlayerUri(player, audioUrl, initialPosition);
    }

    if (showNotification) {
      await audioHandler.updateMediaItem(MediaItem(
        id: song.id,
        album: "YouTube",
        title: song.title,
        artist: song.author,
        artUri: artUri,
        duration: duration ?? song.duration,
      ));
    }
    AppLogger.success('Playing from internet stream.', 'AUDIO');
    player.play();
    return updated;
  }
}
