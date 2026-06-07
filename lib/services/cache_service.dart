import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:x_oqs/core/constants/app_constants.dart';
import 'package:x_oqs/core/database/app_database.dart';
import 'package:x_oqs/shared/models/download_job.dart';
import 'package:x_oqs/shared/models/play_history_entry.dart';
import 'package:x_oqs/shared/models/album.dart';
import 'package:x_oqs/shared/models/artist.dart';
import 'package:x_oqs/shared/models/playlist.dart';
import 'package:x_oqs/shared/models/song.dart';
import 'package:x_oqs/shared/models/stream_url_entry.dart';

class CacheService {
  CacheService(this._db);

  final Database _db;

  static Future<CacheService> open() async {
    final db = await AppDatabase.instance.database;
    return CacheService(db);
  }

  Future<void> upsertSongs(Iterable<Song> songs) async {
    final batch = _db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final s in songs) {
      batch.insert(
        'songs',
        {
          'id': s.id,
          'youtube_id': s.youtubeId,
          'title': s.title,
          'artist': s.artist,
          'album': s.album,
          'thumbnail_url': s.thumbnailUrl,
          'duration_sec': s.duration.inSeconds,
          'local_path': s.localPath,
          'is_liked': s.isLiked ? 1 : 0,
          'is_downloaded': s.isDownloaded ? 1 : 0,
          'last_played_ms': s.lastPlayedAt?.millisecondsSinceEpoch,
          'updated_at_ms': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Song>> getSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.rawQuery(
      'SELECT * FROM songs WHERE id IN ($placeholders)',
      ids,
    );
    final byId = {for (final r in rows) r['id']! as String: _songFromRow(r)};
    return ids.map((id) => byId[id]).whereType<Song>().toList();
  }

  Future<Song?> getSong(String id) async {
    final rows = await _db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _songFromRow(rows.first);
  }

  Song _songFromRow(Map<String, Object?> m) {
    return Song(
      id: m['id']! as String,
      youtubeId: m['youtube_id']! as String,
      title: m['title']! as String,
      artist: m['artist']! as String,
      album: m['album']! as String,
      thumbnailUrl: m['thumbnail_url'] as String?,
      duration: Duration(seconds: (m['duration_sec'] as int?) ?? 0),
      localPath: m['local_path'] as String?,
      isLiked: (m['is_liked'] as int? ?? 0) == 1,
      isDownloaded: (m['is_downloaded'] as int? ?? 0) == 1,
      lastPlayedAt: (m['last_played_ms'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(m['last_played_ms']! as int)
          : null,
    );
  }

  Future<void> upsertSearchResults(String query, Iterable<Song> songs) async {
    final key = query.trim().toLowerCase();
    final list = songs.map((s) => s.toJson()).toList();
    await _db.insert(
      'search_cache',
      {
        'query_key': key,
        'payload': jsonEncode(list),
        'cached_at_ms': DateTime.now().millisecondsSinceEpoch,
        'ttl_sec': AppConstants.searchCacheTtl.inSeconds,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await upsertSongs(songs);
  }

  Future<List<Song>> getCachedSearch(String query) async {
    final key = query.trim().toLowerCase();
    final rows = await _db.query(
      'search_cache',
      where: 'query_key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return [];
    final cachedAt = rows.first['cached_at_ms']! as int;
    final ttl = rows.first['ttl_sec']! as int;
    if (DateTime.now().millisecondsSinceEpoch - cachedAt > ttl * 1000) {
      return [];
    }
    final payload = jsonDecode(rows.first['payload']! as String) as List<dynamic>;
    return payload
        .map((e) => Song.fromJson(Map<String, Object?>.from(e as Map)))
        .toList();
  }

  Future<void> putStreamUrl(StreamUrlEntry entry) async {
    await _db.insert(
      'stream_url_cache',
      {
        'youtube_id': entry.youtubeId,
        'url': entry.url,
        'expires_at_ms': entry.expiresAt.millisecondsSinceEpoch,
        'quality_label': entry.qualityLabel,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<StreamUrlEntry?> getValidStreamUrl(String youtubeId) async {
    final rows = await _db.query(
      'stream_url_cache',
      where: 'youtube_id = ?',
      whereArgs: [youtubeId],
    );
    if (rows.isEmpty) return null;
    final exp = rows.first['expires_at_ms']! as int;
    if (DateTime.now().millisecondsSinceEpoch >= exp) return null;
    return StreamUrlEntry(
      youtubeId: youtubeId,
      url: rows.first['url']! as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp),
      qualityLabel: rows.first['quality_label'] as String?,
    );
  }

  Future<void> recordPlay(PlayHistoryEntry entry) async {
    await _db.insert('play_history', {
      'song_id': entry.songId,
      'played_at_ms': entry.playedAt.millisecondsSinceEpoch,
      'listen_sec': entry.listenDuration.inSeconds,
    });
    await _db.update(
      'songs',
      {'last_played_ms': entry.playedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [entry.songId],
    );
  }

  Future<List<Song>> getRecentlyPlayed({int limit = AppConstants.recentlyPlayedLimit}) async {
    final rows = await _db.rawQuery('''
SELECT DISTINCT s.* FROM songs s
INNER JOIN (
  SELECT song_id, MAX(played_at_ms) AS mx FROM play_history GROUP BY song_id
) h ON s.id = h.song_id
ORDER BY h.mx DESC
LIMIT ?
''', [limit]);
    return rows.map(_songFromRow).toList();
  }

  Future<List<Song>> getLikedSongs() async {
    final rows = await _db.query(
      'songs',
      where: 'is_liked = 1',
      orderBy: 'updated_at_ms DESC',
    );
    return rows.map(_songFromRow).toList();
  }

  Future<void> setLiked(String songId, bool liked) async {
    await _db.update(
      'songs',
      {'is_liked': liked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<List<Song>> getDownloadedSongs() async {
    final rows = await _db.query(
      'songs',
      where: 'local_path IS NOT NULL AND local_path != ?',
      whereArgs: [''],
    );
    return rows.map(_songFromRow).toList();
  }

  Future<List<Playlist>> getPlaylists() async {
    final rows = await _db.query('playlists', orderBy: 'updated_at_ms DESC');
    return rows.map(_playlistFromRow).toList();
  }

  Playlist _playlistFromRow(Map<String, Object?> m) {
    return Playlist(
      id: m['id']! as String,
      name: m['name']! as String,
      description: m['description']! as String,
      coverUrl: m['cover_url'] as String?,
      trackIds: AppDatabase.decodeTrackIds(m['track_ids']! as String),
      isSpotifyImport: (m['is_spotify_import'] as int? ?? 0) == 1,
      spotifyId: m['spotify_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at_ms']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at_ms']! as int),
    );
  }

  Future<void> savePlaylist(Playlist pl) async {
    await _db.insert(
      'playlists',
      {
        'id': pl.id,
        'name': pl.name,
        'description': pl.description,
        'cover_url': pl.coverUrl,
        'track_ids': AppDatabase.encodeTrackIds(pl.trackIds),
        'is_spotify_import': pl.isSpotifyImport ? 1 : 0,
        'spotify_id': pl.spotifyId,
        'created_at_ms': pl.createdAt.millisecondsSinceEpoch,
        'updated_at_ms': pl.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePlaylist(String id) async {
    await _db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<Playlist?> getPlaylist(String id) async {
    final rows = await _db.query('playlists', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _playlistFromRow(rows.first);
  }

  Future<List<Artist>> getFollowedArtists() async {
    final rows = await _db.query(
      'artists',
      where: 'is_followed = 1',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows
        .map(
          (m) => Artist(
            id: m['id']! as String,
            name: m['name']! as String,
            imageUrl: m['image_url'] as String?,
            isFollowed: true,
          ),
        )
        .toList();
  }

  Future<Artist?> getArtist(String id) async {
    final rows = await _db.query('artists', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final m = rows.first;
    return Artist(
      id: m['id']! as String,
      name: m['name']! as String,
      imageUrl: m['image_url'] as String?,
      isFollowed: (m['is_followed'] as int? ?? 0) == 1,
    );
  }

  Future<void> upsertArtist(Artist a) async {
    await _db.insert(
      'artists',
      {
        'id': a.id,
        'name': a.name,
        'image_url': a.imageUrl,
        'is_followed': a.isFollowed ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Album>> getSavedAlbums() async {
    final rows = await _db.query('albums', orderBy: 'title COLLATE NOCASE');
    return rows
        .map(
          (m) => Album(
            id: m['id']! as String,
            title: m['title']! as String,
            artistName: m['artist_name']! as String,
            coverUrl: m['cover_url'] as String?,
            year: m['year'] as int?,
            trackIds: AppDatabase.decodeTrackIds(m['track_ids']! as String),
          ),
        )
        .toList();
  }

  Future<void> saveAlbum(Album a) async {
    await _db.insert(
      'albums',
      {
        'id': a.id,
        'title': a.title,
        'artist_name': a.artistName,
        'cover_url': a.coverUrl,
        'year': a.year,
        'track_ids': AppDatabase.encodeTrackIds(a.trackIds),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DownloadJob>> getDownloadJobs() async {
    final rows = await _db.query('download_jobs');
    return rows.map(_jobFromRow).toList();
  }

  DownloadJob _jobFromRow(Map<String, Object?> m) {
    return DownloadJob(
      id: m['job_id']! as String,
      songId: m['song_id']! as String,
      status: DownloadJobStatus.values[m['status']! as int],
      progress: (m['progress'] as num).toDouble(),
      qualityKbps: m['quality_kbps']! as int,
      targetPath: m['target_path']! as String,
      errorMessage: m['error_message'] as String?,
    );
  }

  Future<void> upsertDownloadJob(DownloadJob job) async {
    await _db.insert(
      'download_jobs',
      {
        'job_id': job.id,
        'song_id': job.songId,
        'status': job.status.index,
        'progress': job.progress,
        'quality_kbps': job.qualityKbps,
        'target_path': job.targetPath,
        'error_message': job.errorMessage,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeDownloadJob(String jobId) async {
    await _db.delete('download_jobs', where: 'job_id = ?', whereArgs: [jobId]);
  }

  Future<void> clearStreamAndSearchCache() async {
    await _db.delete('stream_url_cache');
    await _db.delete('search_cache');
  }

  /// Evict downloaded files LRU until total bytes under [maxBytes].
  Future<void> evictLRUUntilUnderBytes(
    int maxBytes, {
    required int Function(String path) fileSize,
    required Future<void> Function(String path) deleteFile,
  }) async {
    final rows = await _db.query(
      'songs',
      columns: ['id', 'local_path', 'last_played_ms', 'updated_at_ms'],
      where: 'local_path IS NOT NULL AND local_path != ?',
      whereArgs: [''],
    );
    var total = 0;
    final entries = <_LruEntry>[];
    for (final r in rows) {
      final path = r['local_path']! as String;
      final sz = fileSize(path);
      if (sz <= 0) continue;
      total += sz;
      final touch = (r['last_played_ms'] as int?) ?? (r['updated_at_ms'] as int?) ?? 0;
      entries.add(_LruEntry(id: r['id']! as String, path: path, size: sz, touchMs: touch));
    }
    entries.sort((a, b) => a.touchMs.compareTo(b.touchMs));
    while (total > maxBytes && entries.isNotEmpty) {
      final victim = entries.removeAt(0);
      total -= victim.size;
      await _db.update(
        'songs',
        {
          'local_path': null,
          'is_downloaded': 0,
        },
        where: 'id = ?',
        whereArgs: [victim.id],
      );
      await deleteFile(victim.path);
    }
  }
}

class _LruEntry {
  _LruEntry({
    required this.id,
    required this.path,
    required this.size,
    required this.touchMs,
  });

  final String id;
  final String path;
  final int size;
  final int touchMs;
}
