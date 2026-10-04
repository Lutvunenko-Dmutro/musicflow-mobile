import 'dart:io';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/audio_handler.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class PlaybackManager {
  static Uri? _defaultArtUri;

  static Future<void> ensureDefaultArtPrepared() async {
    if (_defaultArtUri == null) {
      try {
        final byteData = await rootBundle.load('assets/icon.png');
        final tempDir = await getApplicationDocumentsDirectory();
        final file = File('${tempDir.path}/default_cover.png');
        if (!await file.exists()) {
          await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        }
        _defaultArtUri = file.uri;
      } catch (e) {
        AppLogger.error('Failed to load default cover art: $e');
      }
    }
  }

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
    await ensureDefaultArtPrepared();
    final prefs = await SharedPreferences.getInstance();
    final showNotification = prefs.getBool('show_media_notification') ?? true;

    if (showNotification && await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    SongModel updatedSong = song;

    bool playLocally = song.isLocal && song.localPath != null;
    if (playLocally) {
      if (!File(song.localPath!).existsSync()) {
        // If the ID is a valid YouTube ID (typically 11 chars), fallback to internet
        if (song.id.length == 11 && !song.id.contains('/')) {
          AppLogger.warning('Local file not found, falling back to internet stream.', 'AUDIO');
          playLocally = false;
          updatedSong = updatedSong.copyWith(isLocal: false, localPath: null);
        } else {
          // If it's a randomly scanned local file, its ID is its file path. We can't stream it.
          throw Exception('Локальний файл не знайдено, а потокове відтворення неможливе.');
        }
      }
    }

    if (playLocally) {
      AppLogger.audio('Source: Local Storage');
      final duration = await player.setAudioSource(
        AudioSource.file(updatedSong.localPath!),
        initialPosition: initialPosition,
      );

      Uri? localArtUri = _defaultArtUri;
      if (song.coverBytes != null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final safeId = song.id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          final file = File('${tempDir.path}/${safeId}_local_cover.jpg');
          if (!await file.exists()) {
            await file.writeAsBytes(song.coverBytes!);
          }
          if (await file.exists()) {
            localArtUri = file.uri;
          }
        } catch (e) {
          AppLogger.error('Failed to write local cover for notification: $e');
        }
      }

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
      if (duration != null) {
        updatedSong = updatedSong.copyWith(duration: duration);
      }
      AppLogger.success('Playing directly from device.', 'AUDIO');
      player.play();
    } else {
      AppLogger.audio('Source: Internet (YouTube)');
      String? audioUrl = song.streamUrl;
      
      // Якщо посилання відсутнє або термін його дії закінчився (>6 годин)
      if (audioUrl == null || isYoutubeUrlExpired(audioUrl)) {
        AppLogger.info('Fetching fresh stream URL from YoutubeService...', 'AUDIO');
        audioUrl = await ytService.getAudioStreamUrl(song.id);
        AppLogger.success('Stream URL fetched.', 'AUDIO');
        updatedSong = updatedSong.copyWith(streamUrl: audioUrl);
      }

      if (audioUrl != null) {
        AppLogger.info('Connecting to just_audio...', 'AUDIO');
        
        Uri? artUri = _defaultArtUri;
        if (song.coverUrl.isNotEmpty) {
          try {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/${song.id}_cover.jpg');
            if (!await file.exists()) {
              final response = await http.get(Uri.parse(song.coverUrl));
              if (response.statusCode == 200) {
                await file.writeAsBytes(response.bodyBytes);
              }
            }
            if (await file.exists()) {
              artUri = file.uri;
            }
          } catch (e) {
            AppLogger.error('Failed to download cover for notification: $e');
          }
        }

        Duration? duration;
        try {
          duration = await _setPlayerUri(player, audioUrl, initialPosition);
        } catch (e) {
          if (e.toString().contains('Loading interrupted')) rethrow;
          AppLogger.warning('Stream error ($e), attempting refresh with new YouTube URL...', 'AUDIO');
          audioUrl = await ytService.getAudioStreamUrl(song.id);
          if (audioUrl == null) rethrow;
          updatedSong = updatedSong.copyWith(streamUrl: audioUrl);
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
      } else {
        AppLogger.error('Failed to fetch audioUrl!', null, null, 'AUDIO');
        throw Exception('Ця пісня недоступна для відтворення (обмеження YouTube).');
      }
    }
    return updatedSong;
  }
}
