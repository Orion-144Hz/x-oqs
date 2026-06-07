import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:x_oqs/core/storage/download_paths.dart';
import 'package:x_oqs/core/storage/storage_quota_manager.dart';
import 'package:x_oqs/services/cache_service.dart';
import 'package:x_oqs/services/youtube_music_service.dart';
import 'package:x_oqs/shared/models/download_job.dart';
import 'package:x_oqs/shared/models/song.dart';

class DownloadService {
  DownloadService(
    this._cache,
    this._yt,
    this._dio,
    this._quota,
  );

  final CacheService _cache;
  final YoutubeMusicService _yt;
  final Dio _dio;
  final StorageQuotaManager _quota;

  final _uuid = const Uuid();
  final _jobs = <String, DownloadJob>{};
  final _controllers = <StreamController<List<DownloadJob>>>[];
  var _active = 0;
  static const _maxConcurrent = 2;

  Stream<List<DownloadJob>> watchJobs() {
    late StreamController<List<DownloadJob>> c;
    c = StreamController<List<DownloadJob>>(
      onListen: () => c.add(_jobs.values.toList()),
    );
    _controllers.add(c);
    c.onCancel = () => _controllers.remove(c);
    return c.stream;
  }

  void _emit() {
    final list = _jobs.values.toList();
    for (final c in _controllers) {
      if (!c.isClosed) c.add(list);
    }
  }

  Future<void> enqueue(Song song, {required int kbps, int? storageLimitBytes}) async {
    final root = await tracksDirectory();
    await Directory(root).create(recursive: true);
    final id = _uuid.v4();
    final path = p.join(root, '${song.youtubeId}.m4a');
    final job = DownloadJob(
      id: id,
      songId: song.id,
      status: DownloadJobStatus.queued,
      progress: 0,
      qualityKbps: kbps,
      targetPath: path,
    );
    _jobs[id] = job;
    await _cache.upsertDownloadJob(job);
    _emit();
    unawaited(_pump(storageLimitBytes));
  }

  Future<void> _pump(int? storageLimitBytes) async {
    while (_active < _maxConcurrent) {
      final next = _jobs.values.where((j) => j.status == DownloadJobStatus.queued).firstOrNull;
      if (next == null) return;
      _active++;
      unawaited(_run(next, storageLimitBytes).whenComplete(() {
        _active--;
        unawaited(_pump(storageLimitBytes));
      }));
    }
  }

  Future<void> _run(DownloadJob job, int? storageLimitBytes) async {
    _update(job.id, (j) => j.copyWith(status: DownloadJobStatus.running, progress: 0));
    try {
      final song = await _cache.getSong(job.songId);
      if (song == null) throw StateError('Song not in cache');
      final uri = await _yt.getBestAudioUri(song.youtubeId, maxKbps: job.qualityKbps);
      await _dio.download(
        uri.toString(),
        job.targetPath,
        onReceiveProgress: (c, t) {
          if (t <= 0) return;
          _update(
            job.id,
            (j) => j.copyWith(progress: c / t),
          );
        },
      );
      final updatedSong = song.copyWith(
        localPath: job.targetPath,
        isDownloaded: true,
      );
      await _cache.upsertSongs([updatedSong]);
      _update(
        job.id,
        (j) => j.copyWith(status: DownloadJobStatus.completed, progress: 1),
      );
      await _cache.removeDownloadJob(job.id);
      _jobs.remove(job.id);
      if (storageLimitBytes != null) {
        final dir = Directory(p.dirname(job.targetPath));
        await _quota.enforceLimit(maxBytes: storageLimitBytes, downloadsRoot: dir);
      }
    } catch (e) {
      _update(
        job.id,
        (j) => j.copyWith(
          status: DownloadJobStatus.failed,
          errorMessage: e.toString(),
        ),
      );
    }
    _emit();
  }

  void _update(String id, DownloadJob Function(DownloadJob) fn) {
    final j = _jobs[id];
    if (j == null) return;
    _jobs[id] = fn(j);
    _cache.upsertDownloadJob(_jobs[id]!);
    _emit();
  }

  Future<void> pause(String jobId) async {
    // Dio download pause not wired; mark paused for future work.
    _update(jobId, (j) => j.copyWith(status: DownloadJobStatus.paused));
  }

  Future<void> resume(String jobId) async {
    _update(jobId, (j) => j.copyWith(status: DownloadJobStatus.queued));
    _emit();
    await _pump(null);
  }

  Future<void> cancel(String jobId) async {
    _jobs.remove(jobId);
    await _cache.removeDownloadJob(jobId);
    _emit();
  }

  Future<void> deleteLocal(Song song) async {
    final path = song.localPath;
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await _cache.upsertSongs([
      song.copyWith(localPath: null, isDownloaded: false),
    ]);
  }

  Future<int> getTotalBytesUsed() async {
    final root = Directory(await tracksDirectory());
    return _quota.directoryBytes(root);
  }
}

extension on DownloadJob {
  DownloadJob copyWith({
    DownloadJobStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return DownloadJob(
      id: id,
      songId: songId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      qualityKbps: qualityKbps,
      targetPath: targetPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
