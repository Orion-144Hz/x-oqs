import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:uuid/uuid.dart';
import 'package:x_oqs/core/constants/app_constants.dart';
import 'package:x_oqs/core/network/api_endpoints.dart';
import 'package:x_oqs/core/storage/secure_token_store.dart';
import 'package:x_oqs/services/cache_service.dart';
import 'package:x_oqs/services/youtube_music_service.dart';
import 'package:x_oqs/shared/models/album.dart';
import 'package:x_oqs/shared/models/artist.dart';
import 'package:x_oqs/shared/models/play_history_entry.dart';
import 'package:x_oqs/shared/models/playlist.dart';
import 'package:x_oqs/shared/models/song.dart';

class UnmatchedTrack {
  UnmatchedTrack({
    required this.spotifyUri,
    required this.artist,
    required this.title,
    this.album,
  });

  final String spotifyUri;
  final String artist;
  final String title;
  final String? album;
}

class ImportProgress {
  ImportProgress({
    required this.phase,
    required this.done,
    required this.total,
    required this.matched,
    required this.unmatched,
  });

  final String phase;
  final int done;
  final int total;
  final int matched;
  final int unmatched;
}

class SpotifyLibrarySnapshot {
  SpotifyLibrarySnapshot({
    required this.likedTracks,
    required this.playlists,
    required this.followedArtists,
    required this.savedAlbums,
    required this.recent,
  });

  final List<Map<String, dynamic>> likedTracks;
  final List<Map<String, dynamic>> playlists;
  final List<Map<String, dynamic>> followedArtists;
  final List<Map<String, dynamic>> savedAlbums;
  final List<Map<String, dynamic>> recent;
}

class SpotifyImportService {
  SpotifyImportService(
    this._tokens,
    this._yt,
    this._cache, {
    Dio? dio,
    FlutterAppAuth? appAuth,
    required this.clientId,
  })  : _dio = dio ?? Dio(),
        _appAuth = appAuth ?? const FlutterAppAuth();

  final SecureTokenStore _tokens;
  final YoutubeMusicService _yt;
  final CacheService _cache;
  final Dio _dio;
  final FlutterAppAuth _appAuth;
  final String clientId;

  final _unmatched = <UnmatchedTrack>[];
  final _uuid = const Uuid();

  Future<List<UnmatchedTrack>> getUnmatched() async => List.unmodifiable(_unmatched);

  Future<void> startPkceLogin() async {
    if (clientId.isEmpty) {
      throw StateError('Set SPOTIFY_CLIENT_ID via --dart-define=SPOTIFY_CLIENT_ID=...');
    }
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        AppConstants.spotifyRedirectUri,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: '${ApiEndpoints.spotifyAccounts}/authorize',
          tokenEndpoint: '${ApiEndpoints.spotifyAccounts}/api/token',
        ),
        scopes: [
          'user-library-read',
          'playlist-read-private',
          'playlist-read-collaborative',
          'user-follow-read',
          'user-read-recently-played',
          'user-saved-albums-read',
        ],
      ),
    );
    if (result.accessToken == null || result.refreshToken == null) {
      throw StateError('Spotify auth cancelled or incomplete');
    }
    final expiry = result.accessTokenExpirationDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    await _tokens.saveSpotifyTokens(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken!,
      expiresAt: expiry,
    );
  }

  Future<void> refreshTokenIfNeeded() async {
    final exp = await _tokens.getAccessExpiry();
    final refresh = await _tokens.getRefreshToken();
    if (exp == null || refresh == null) return;
    if (DateTime.now().isBefore(exp.subtract(const Duration(minutes: 2)))) return;
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.spotifyAccounts}/api/token',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
        'client_id': clientId,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    final data = res.data!;
    final access = data['access_token'] as String;
    final newRefresh = data['refresh_token'] as String? ?? refresh;
    final expiresIn = (data['expires_in'] as num).toInt();
    await _tokens.saveSpotifyTokens(
      accessToken: access,
      refreshToken: newRefresh,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Future<String> _authHeader() async {
    await refreshTokenIfNeeded();
    final t = await _tokens.getAccessToken();
    if (t == null) throw StateError('Not logged in to Spotify');
    return 'Bearer $t';
  }

  Future<SpotifyLibrarySnapshot> fetchFullLibrary() async {
    final h = await _authHeader();
    final liked = await _paginateTracks(
      '${ApiEndpoints.spotifyApi}/me/tracks',
      h,
    );
    final playlists = await _paginateItems(
      '${ApiEndpoints.spotifyApi}/me/playlists',
      h,
    );
    final following = await _fetchFollowing(h);
    final albums = await _paginateItems(
      '${ApiEndpoints.spotifyApi}/me/albums',
      h,
    );
    final recent = await _paginateItems(
      '${ApiEndpoints.spotifyApi}/me/player/recently-played',
      h,
    );
    return SpotifyLibrarySnapshot(
      likedTracks: liked,
      playlists: playlists,
      followedArtists: following,
      savedAlbums: albums,
      recent: recent,
    );
  }

  Future<List<Map<String, dynamic>>> _paginateTracks(String firstUrl, String auth) async {
    final out = <Map<String, dynamic>>[];
    String? url = firstUrl;
    while (url != null) {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {'Authorization': auth}),
      );
      final j = res.data!;
      out.addAll((j['items'] as List<dynamic>).cast<Map<String, dynamic>>());
      url = j['next'] as String?;
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _paginateItems(String firstUrl, String auth) async {
    final out = <Map<String, dynamic>>[];
    String? url = firstUrl;
    while (url != null) {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {'Authorization': auth}),
      );
      final j = res.data!;
      out.addAll((j['items'] as List<dynamic>).cast<Map<String, dynamic>>());
      url = j['next'] as String?;
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _fetchFollowing(String auth) async {
    final out = <Map<String, dynamic>>[];
    String? url = '${ApiEndpoints.spotifyApi}/me/following?type=artist&limit=50';
    while (url != null) {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {'Authorization': auth}),
      );
      final j = res.data!;
      final artists = (j['artists'] as Map<String, dynamic>?) ?? {};
      out.addAll((artists['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      url = artists['next'] as String?;
    }
    return out;
  }

  Stream<ImportProgress> importLibrary(SpotifyLibrarySnapshot snap) async* {
    _unmatched.clear();
    var matched = 0;
    var unmatched = 0;
    final total = snap.likedTracks.length;
    var done = 0;
    yield ImportProgress(
      phase: 'liked',
      done: done,
      total: total,
      matched: matched,
      unmatched: unmatched,
    );
    for (final item in snap.likedTracks) {
      final track = item['track'] as Map<String, dynamic>?;
      if (track == null) {
        done++;
        continue;
      }
      final name = track['name'] as String? ?? '';
      final artists = (track['artists'] as List<dynamic>? ?? [])
          .map((e) => (e as Map)['name'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .join(', ');
      final album = (track['album'] as Map<String, dynamic>?)?['name'] as String?;
      final uri = track['uri'] as String? ?? '';
      final song = await _yt.matchTrackToYoutube(
        artist: artists,
        title: name,
        album: album,
      );
      if (song != null) {
        await _cache.upsertSongs([song.copyWith(isLiked: true)]);
        await _cache.setLiked(song.id, true);
        matched++;
      } else {
        unmatched++;
        _unmatched.add(
          UnmatchedTrack(spotifyUri: uri, artist: artists, title: name, album: album),
        );
      }
      done++;
      yield ImportProgress(
        phase: 'liked',
        done: done,
        total: total,
        matched: matched,
        unmatched: unmatched,
      );
    }

    for (final pl in snap.playlists) {
      final id = pl['id'] as String;
      final name = pl['name'] as String? ?? 'Playlist';
      final images = pl['images'] as List<dynamic>? ?? [];
      String? cover;
      if (images.isNotEmpty) {
        cover = (images.first as Map)['url'] as String?;
      }
      final tracks = await _playlistTracks(id, await _authHeader());
      final ids = <String>[];
      for (final t in tracks) {
        final track = t['track'] as Map<String, dynamic>?;
        if (track == null) continue;
        final tname = track['name'] as String? ?? '';
        final artists = (track['artists'] as List<dynamic>? ?? [])
            .map((e) => (e as Map)['name'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .join(', ');
        final album = (track['album'] as Map<String, dynamic>?)?['name'] as String?;
        final song = await _yt.matchTrackToYoutube(
          artist: artists,
          title: tname,
          album: album,
        );
        if (song != null) {
          await _cache.upsertSongs([song]);
          ids.add(song.id);
        } else {
          _unmatched.add(
            UnmatchedTrack(
              spotifyUri: track['uri'] as String? ?? '',
              artist: artists,
              title: tname,
              album: album,
            ),
          );
        }
      }
      final playlist = Playlist(
        id: _uuid.v4(),
        name: name,
        coverUrl: cover,
        trackIds: ids,
        isSpotifyImport: true,
        spotifyId: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _cache.savePlaylist(playlist);
    }

    for (final a in snap.followedArtists) {
      await _cache.upsertArtist(
        Artist(
          id: a['id'] as String,
          name: a['name'] as String,
          imageUrl: (a['images'] as List<dynamic>?)?.isNotEmpty == true
              ? ((a['images'] as List).first as Map)['url'] as String?
              : null,
          isFollowed: true,
        ),
      );
    }

    for (final wrap in snap.savedAlbums) {
      final alb = wrap['album'] as Map<String, dynamic>?;
      if (alb == null) continue;
      final aid = alb['id'] as String;
      final title = alb['name'] as String? ?? 'Album';
      final artists = (alb['artists'] as List<dynamic>? ?? [])
          .map((e) => (e as Map)['name'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .join(', ');
      final year = int.tryParse(
        (alb['release_date'] as String?)?.substring(0, 4) ?? '',
      );
      final cover = (alb['images'] as List<dynamic>?)?.isNotEmpty == true
          ? ((alb['images'] as List).first as Map)['url'] as String?
          : null;
      final tracks = (alb['tracks'] as Map<String, dynamic>?)?['items'] as List<dynamic>? ?? [];
      final ids = <String>[];
      for (final tr in tracks) {
        final track = tr as Map<String, dynamic>;
        final tname = track['name'] as String? ?? '';
        final song = await _yt.matchTrackToYoutube(artist: artists, title: tname);
        if (song != null) {
          await _cache.upsertSongs([song]);
          ids.add(song.id);
        }
      }
      await _cache.saveAlbum(
        Album(
          id: aid,
          title: title,
          artistName: artists,
          coverUrl: cover,
          year: year,
          trackIds: ids,
        ),
      );
    }

    for (final item in snap.recent) {
      final track = item['track'] as Map<String, dynamic>?;
      if (track == null) continue;
      final tname = track['name'] as String? ?? '';
      final artists = (track['artists'] as List<dynamic>? ?? [])
          .map((e) => (e as Map)['name'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .join(', ');
      final song = await _yt.matchTrackToYoutube(artist: artists, title: tname);
      if (song != null) {
        await _cache.upsertSongs([song]);
        await _cache.recordPlay(
          PlayHistoryEntry(
            songId: song.id,
            playedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _playlistTracks(String playlistId, String auth) async {
    final out = <Map<String, dynamic>>[];
    String? url = '${ApiEndpoints.spotifyApi}/playlists/$playlistId/tracks';
    while (url != null) {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {'Authorization': auth}),
      );
      final j = res.data!;
      out.addAll((j['items'] as List<dynamic>).cast<Map<String, dynamic>>());
      url = j['next'] as String?;
    }
    return out;
  }
}
