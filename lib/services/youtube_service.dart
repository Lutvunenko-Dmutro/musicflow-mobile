import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import '../utils/app_logger.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Search for songs/videos based on query
  Future<List<SongModel>> searchSongs(String query) async {
    try {
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
    } catch (e) {
      AppLogger.error('Error searching songs', e, null, 'YOUTUBE');
      return [];
    }
  }

  /// Get the actual stream info for downloading
  Future<dynamic> getAudioStreamInfo(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.container.name == 'm4a');
      final streamInfo = audioStreams.isNotEmpty ? audioStreams.withHighestBitrate() : manifest.audioOnly.withHighestBitrate();
      return streamInfo;
    } catch (e) {
      AppLogger.error('Error getting audio stream info', e, null, 'YOUTUBE');
      return null;
    }
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
      return null;
    }
  }

  /// Resolve a specific link (video or playlist)
  Future<List<SongModel>> resolveLink(String url) async {
    try {
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
    } catch (e) {
      AppLogger.error('Error resolving link', e, null, 'YOUTUBE');
      return [];
    }
  }

  void dispose() {
    _yt.close();
  }
}
