import 'package:x_oqs/core/constants/app_constants.dart';
import 'package:x_oqs/shared/models/song.dart';
import 'package:x_oqs/shared/models/stream_url_entry.dart';
import 'package:x_oqs/services/cache_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchResultsPage {
  SearchResultsPage({required this.songs, this.continuationToken});

  final List<Song> songs;
  final String? continuationToken;
}

/// Resolves YouTube search + stream URLs; caches URLs in [CacheService].
class YoutubeMusicService {
  YoutubeMusicService(this._cache, {YoutubeExplode? explode})
      : _yt = explode ?? YoutubeExplode();

  final CacheService _cache;
  final YoutubeExplode _yt;

  Future<void> close() async {
    _yt.close();
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    return _yt.search.getQuerySuggestions(query);
  }

  Future<SearchResultsPage> search(
    String query, {
    String? continuationToken,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return SearchResultsPage(songs: []);
    }
    if (continuationToken == null) {
      final cached = await _cache.getCachedSearch(trimmed);
      if (cached.isNotEmpty) {
        return SearchResultsPage(songs: cached);
      }
    }

    final list = await _yt.search.search(trimmed);
    final songs = <Song>[];
    for (final v in list) {
      songs.add(_songFromSearchVideo(v));
    }
    if (continuationToken == null) {
      await _cache.upsertSearchResults(trimmed, songs);
    }
    return SearchResultsPage(
      songs: songs,
      continuationToken: list.isNotEmpty && list.length >= 20 ? 'more' : null,
    );
  }

  Song _songFromSearchVideo(Video video) {
    final thumb = video.thumbnails.highResUrl;
    return Song(
      id: video.id.value,
      youtubeId: video.id.value,
      title: video.title,
      artist: video.author,
      album: '',
      thumbnailUrl: thumb,
      duration: video.duration ?? Duration.zero,
    );
  }

  Future<Song> resolveSongFromVideoId(String youtubeId) async {
    final video = await _yt.videos.get(VideoId(youtubeId));
    return Song(
      id: video.id.value,
      youtubeId: video.id.value,
      title: video.title,
      artist: video.author,
      album: '',
      thumbnailUrl: video.thumbnails.highResUrl,
      duration: video.duration ?? Duration.zero,
    );
  }

  Future<StreamManifest> getStreamManifest(String youtubeId) {
    return _yt.videos.streams.getManifest(VideoId(youtubeId));
  }

  /// Picks best AAC/M4A-ish audio under [maxKbps] when possible.
  Future<Uri> getBestAudioUri(String youtubeId, {int? maxKbps}) async {
    final cached = await _cache.getValidStreamUrl(youtubeId);
    if (cached != null && cached.isValid) {
      return Uri.parse(cached.url);
    }

    final manifest = await getStreamManifest(youtubeId);
    final audioOnly = manifest.audioOnly;
    if (audioOnly.isEmpty) {
      throw StateError('No audio streams for $youtubeId');
    }

    final best = audioOnly.withHighestBitrate();
    final url = best.url.toString();
    final expiresAt = DateTime.now().add(AppConstants.streamUrlTtl);
    await _cache.putStreamUrl(
      StreamUrlEntry(
        youtubeId: youtubeId,
        url: url,
        expiresAt: expiresAt,
        qualityLabel: best.audioCodec,
      ),
    );
    return best.url;
  }

  /// Spotify-style match query.
  Future<Song?> matchTrackToYoutube({
    required String artist,
    required String title,
    String? album,
  }) async {
    final q = album != null && album.isNotEmpty
        ? '$artist - $title $album'
        : '$artist - $title';
    final page = await search(q);
    if (page.songs.isEmpty) return null;
    return page.songs.first;
  }
}
