import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/models/search_filter_model.dart';
import 'package:music_flow_mobile/services/youtube_caption_service.dart';
import 'package:music_flow_mobile/utils/music_search_filter.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class YoutubeService {
  YoutubeExplode _yt = YoutubeExplode();

  void _resetClient() {
    try {
      _yt.close();
    } catch (_) {}
    _yt = YoutubeExplode();
  }

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
        if (e is VideoUnplayableException || e.toString().contains('VideoUnplayableException')) {
          AppLogger.error('Video is unplayable (restricted on YouTube): $e', e, st, 'YOUTUBE');
          rethrow;
        }
        if (attempt >= maxAttempts) {
          _resetClient();
          AppLogger.error('Failed $operationName after $attempt attempts: $e', e, st, 'YOUTUBE');
          rethrow;
        }
        _resetClient();
        AppLogger.warning('$operationName failed ($attempt/$maxAttempts): $e', 'YOUTUBE');
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<List<SongModel>> searchSongs(String query, {SearchFilterModel? filter}) async {
    final activeFilter = filter ?? const SearchFilterModel();
    return _retryWithBackoff(() async {
      final targetQuery = activeFilter.buildTargetQuery(query);
      SearchFilter sf = const SearchFilter('');
      if (activeFilter.sortBy == SearchSortBy.views) sf = SortFilters.viewCount;
      if (activeFilter.sortBy == SearchSortBy.newest) sf = SortFilters.uploadDate;

      final res = await _yt.search.searchContent(targetQuery, filter: sf);
      final songs = <SongModel>[];
      for (final item in res) {
        final song = _mapSearchItem(item, activeFilter);
        if (song != null) songs.add(song);
      }

      if (songs.length < 3 && targetQuery != query) {
        try {
          final fallback = await _yt.search.searchContent(query, filter: sf);
          for (final item in fallback) {
            final song = _mapSearchItem(item, activeFilter);
            if (song != null && !songs.any((s) => s.id == song.id)) {
              songs.add(song);
            }
          }
        } catch (_) {}
      }

      return songs;
    }, operationName: 'searchSongs("$query")');
  }

  SongModel? _mapSearchItem(dynamic item, SearchFilterModel filter) {
    if (item is! SearchVideo || item.isLive) return null;
    final dur = MusicSearchFilter.parseDuration(item.duration);
    if (!filter.matchesDuration(dur)) return null;
    return SongModel(
      id: item.id.value,
      title: item.title,
      author: item.author,
      duration: dur,
      coverUrl: ThumbnailSet(item.id.value).highResUrl,
    );
  }

  Future<dynamic> getAudioStreamInfo(String videoId) async {
    return _retryWithBackoff(() async {
      final prefs = await SharedPreferences.getInstance();
      final highQuality = prefs.getBool('high_quality') ?? true;
      
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly
          .where((s) => s.container.name == 'mp4' || s.container.name == 'm4a')
          .toList();
      
      if (audioStreams.isEmpty) {
        return manifest.audioOnly.withHighestBitrate();
      }
      
      audioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
      return highQuality ? audioStreams.last : audioStreams[audioStreams.length ~/ 2];
    }, operationName: 'getAudioStreamInfo($videoId)');
  }

  Stream<List<int>> getStream(dynamic streamInfo) {
    return _yt.videos.streamsClient.get(streamInfo);
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final streamInfo = await getAudioStreamInfo(videoId);
      return streamInfo?.url.toString();
    } catch (e) {
      AppLogger.error('Error getting stream URL', e, null, 'YOUTUBE');
      rethrow;
    }
  }

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

  Future<Map<String, String>?> getYoutubeCaptions(String videoId) {
    return YoutubeCaptionService.getYoutubeCaptions(_yt, videoId);
  }

  void dispose() {
    _yt.close();
  }
}
