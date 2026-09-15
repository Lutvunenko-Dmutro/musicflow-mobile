import 'dart:io';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/youtube_service.dart';
import '../utils/app_logger.dart';

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

  static Future<SongModel> preparePlayback({
    required SongModel song,
    required AudioPlayer player,
    required MusicAudioHandler audioHandler,
    required YoutubeService ytService,
  }) async {
    await ensureDefaultArtPrepared();
    final prefs = await SharedPreferences.getInstance();
    final showNotification = prefs.getBool('show_media_notification') ?? true;

    if (showNotification && await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    SongModel updatedSong = song;

    if (song.isLocal && song.localPath != null) {
      AppLogger.audio('Source: Local Storage');
      final duration = await player.setAudioSource(
        AudioSource.file(song.localPath!),
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
      
      if (audioUrl == null) {
        AppLogger.info('Fetching stream URL from YoutubeService...', 'AUDIO');
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

        final duration = await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(audioUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            },
          ),
        );

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
      }
    }
    return updatedSong;
  }
}
