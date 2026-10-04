import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class YoutubeService {
  YoutubeExplode _yt = YoutubeExplode();

  void _resetClient() {
    try {
      _yt.close();
    } catch (_) {}
    _yt = YoutubeExplode();
  }

  /// Helper to execute network operations with retry and exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    String operationName = 'YouTube operation',
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (e, st) {
        if (attempt >= maxAttempts) {
          _resetClient();
          AppLogger.error('Failed $operationName after $attempt attempts: $e', e, st, 'YOUTUBE');
          rethrow;
        }
        _resetClient();
        AppLogger.warning(
          '$operationName failed (attempt $attempt/$maxAttempts): $e. Retrying in ${delay.inMilliseconds}ms...',
          'YOUTUBE',
        );
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Search for songs/videos based on query
  Future<List<SongModel>> searchSongs(String query) async {
    return _retryWithBackoff(() async {
      final searchResults = await _yt.search.search(query);
      
      return searchResults.map((video) {
        return SongModel(
          id: video.id.value,
          title: video.title,
          author: video.author,
          duration: video.duration ?? Duration.zero,
          coverUrl: video.thumbnails.highResUrl,
        );
      }).toList();
    }, operationName: 'searchSongs("$query")');
  }

  /// Get the actual stream info for downloading
  Future<dynamic> getAudioStreamInfo(String videoId) async {
    return _retryWithBackoff(() async {
      final prefs = await SharedPreferences.getInstance();
      final highQuality = prefs.getBool('high_quality') ?? true;
      
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.container.name == 'm4a').toList();
      
      if (audioStreams.isEmpty) {
        return manifest.audioOnly.withHighestBitrate();
      }
      
      audioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
      
      if (highQuality) {
        return audioStreams.last;
      } else {
        return audioStreams[audioStreams.length ~/ 2]; // Mid quality
      }
    }, operationName: 'getAudioStreamInfo($videoId)');
  }

  /// Get the actual byte stream using youtube_explode_dart's internal client to avoid 403
  Stream<List<int>> getStream(dynamic streamInfo) {
    return _yt.videos.streamsClient.get(streamInfo);
  }

  /// Get audio stream URL
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final streamInfo = await getAudioStreamInfo(videoId);
      return streamInfo?.url.toString();
    } catch (e) {
      AppLogger.error('Error getting stream URL', e, null, 'YOUTUBE');
      rethrow;
    }
  }

  /// Resolve a specific link (video or playlist)
  Future<List<SongModel>> resolveLink(String url) async {
    return _retryWithBackoff(() async {
      if (PlaylistId.validatePlaylistId(url)) {
        final playlist = await _yt.playlists.get(url);
        final videos = await _yt.playlists.getVideos(playlist.id).toList();
        return videos.map((video) {
          return SongModel(
            id: video.id.value,
            title: video.title,
            author: video.author,
            duration: video.duration ?? Duration.zero,
            coverUrl: video.thumbnails.highResUrl,
          );
        }).toList();
      } else {
        // Single video
        final video = await _yt.videos.get(url);
        return [
          SongModel(
            id: video.id.value,
            title: video.title,
            author: video.author,
            duration: video.duration ?? Duration.zero,
            coverUrl: video.thumbnails.highResUrl,
          )
        ];
      }
    }, operationName: 'resolveLink("$url")');
  }

  Future<Map<String, String>?> getYoutubeCaptions(String videoId) async {
    try {
      AppLogger.info('Fetching youtube captions for $videoId', 'YOUTUBE');
      final manifest = await _yt.videos.closedCaptions.getManifest(videoId);
      if (manifest.tracks.isEmpty) return null;
      
      final result = <String, String>{};
      
      // Get all relevant tracks (uk, ru, en)
      final relevantTracks = manifest.tracks.where((t) => 
        t.language.code.startsWith('uk') || 
        t.language.code.startsWith('ru') || 
        t.language.code.startsWith('en')
      ).toList();

      // If no relevant tracks, just take the first one
      if (relevantTracks.isEmpty) {
        relevantTracks.add(manifest.tracks.first);
      }
      
      // Sort to prioritize manual over auto-generated
      relevantTracks.sort((a, b) => a.isAutoGenerated == b.isAutoGenerated ? 0 : (a.isAutoGenerated ? 1 : -1));

      for (var trackInfo in relevantTracks) {
        var track = await _yt.videos.closedCaptions.get(trackInfo);
        
        StringBuffer lrcBuffer = StringBuffer();
        String? currentMergedRaw;
        String? currentMergedLrc;
        Duration? currentMergedStart;
        Duration? lastChunkEnd;
        
        void flushCurrentLine() {
          if (currentMergedLrc != null && currentMergedStart != null) {
            final minutes = currentMergedStart.inMinutes.toString().padLeft(2, '0');
            final seconds = (currentMergedStart.inSeconds % 60).toString().padLeft(2, '0');
            final ms = (currentMergedStart.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
            lrcBuffer.writeln('[$minutes:$seconds.$ms] ${currentMergedLrc.trim()}');
          }
        }

        final Duration leadOffset = trackInfo.isAutoGenerated
            ? const Duration(milliseconds: 350)
            : Duration.zero;

        Duration adjustOffset(Duration original) {
          final adjusted = original - leadOffset;
          return adjusted.isNegative ? Duration.zero : adjusted;
        }

        for (var caption in track.captions) {
          var cleanedText = caption.text.replaceAll('\n', ' ');
          
          cleanedText = cleanedText.replaceAll(RegExp(r'<[^>]*>'), '');
          cleanedText = cleanedText.replaceAll(RegExp(r'\[[^\]]*\]'), '');
          cleanedText = cleanedText.replaceAll(RegExp(r'>>|<<'), '');
          cleanedText = cleanedText.replaceAll(RegExp(r'\s+'), ' ').trim();
          
          if (cleanedText.isEmpty) continue;

          final effectiveOffset = adjustOffset(caption.offset);
          final min = effectiveOffset.inMinutes.toString().padLeft(2, '0');
          final sec = (effectiveOffset.inSeconds % 60).toString().padLeft(2, '0');
          final msec = (effectiveOffset.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
          final timeTag = '<$min:$sec.$msec>';

          if (currentMergedRaw == null) {
            currentMergedRaw = cleanedText;
            currentMergedLrc = '$timeTag $cleanedText';
            currentMergedStart = effectiveOffset;
            lastChunkEnd = effectiveOffset + caption.duration;
          } else {
            bool endsWithPunc = currentMergedRaw.endsWith('.') || 
                                currentMergedRaw.endsWith('!') || 
                                currentMergedRaw.endsWith('?');
            
            bool hasLongGap = false;
            if (lastChunkEnd != null && (effectiveOffset - lastChunkEnd).inMilliseconds > 2000) {
              hasLongGap = true;
            }
            
            if (!endsWithPunc && !hasLongGap && currentMergedRaw.length < 50) {
              currentMergedRaw = '$currentMergedRaw $cleanedText';
              currentMergedLrc = '$currentMergedLrc $timeTag $cleanedText';
              lastChunkEnd = effectiveOffset + caption.duration;
            } else {
              flushCurrentLine();
              currentMergedRaw = cleanedText;
              currentMergedLrc = '$timeTag $cleanedText';
              currentMergedStart = effectiveOffset;
              lastChunkEnd = effectiveOffset + caption.duration;
            }
          }
        }
        
        flushCurrentLine();
        
        final typeStr = trackInfo.isAutoGenerated ? ' (Автоматичні)' : ' (Авторські)';
        var cleanLangName = trackInfo.language.name.replaceAll(' (auto-generated)', '').trim();
        final name = '$cleanLangName$typeStr';
        
        AppLogger.info('Generated LRC:\n${lrcBuffer.toString()}', 'YOUTUBE');

        if (!result.containsKey(name)) {
          result[name] = lrcBuffer.toString();
        }
      }
      
      return result.isNotEmpty ? result : null;
    } catch (e) {
      AppLogger.warning('No youtube captions found for $videoId', 'YOUTUBE');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
