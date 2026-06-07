import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:just_audio/just_audio.dart';
import 'package:x_oqs/services/cache_service.dart';
import 'package:x_oqs/services/sponsor_block_service.dart';
import 'package:x_oqs/services/youtube_music_service.dart';
import 'package:x_oqs/shared/models/play_history_entry.dart' as models;
import 'package:x_oqs/shared/models/song.dart';
import 'package:x_oqs/shared/models/sponsor_segment.dart';

/// Background audio: queue, YouTube URL resolution, SponsorBlock skips.
class XoqsAudioHandler extends BaseAudioHandler with SeekHandler {
  XoqsAudioHandler({
    required YoutubeMusicService youtube,
    required CacheService cache,
    required SponsorBlockService sponsorBlock,
  })  : _yt = youtube,
        _cache = cache,
        _sponsor = sponsorBlock {
    _player.playbackEventStream.listen(_broadcast);
    _player.positionStream.listen(_onPosition);
    _player.playerStateStream.listen((_) => _broadcast(_player.playbackEvent));
  }

  final YoutubeMusicService _yt;
  final CacheService _cache;
  final SponsorBlockService _sponsor;
  final AudioPlayer _player = AudioPlayer();

  final List<Song> _songs = [];
  var _index = 0;
  AudioServiceRepeatMode _repeat = AudioServiceRepeatMode.none;
  List<SponsorSegment> _segments = [];
  Timer? _sleepTimer;
  var _crossfadeSeconds = 0;

  List<Song> get songs => List.unmodifiable(_songs);

  int get currentIndex => _index;

  Future<void> loadQueue(List<Song> songs, {int initialIndex = 0}) async {
    _songs
      ..clear()
      ..addAll(songs);
    if (_songs.isEmpty) {
      queue.add([]);
      mediaItem.add(null);
      return;
    }
    _index = initialIndex.clamp(0, _songs.length - 1);
    queue.add(_songs.map(_toMediaItem).toList());
    await _playIndex(_index);
    _prefetchNext();
  }

  MediaItem _toMediaItem(Song s) {
    return MediaItem(
      id: s.youtubeId,
      title: s.title,
      artist: s.artist,
      album: s.album,
      duration: s.duration,
      artUri: s.thumbnailUrl != null ? Uri.tryParse(s.thumbnailUrl!) : null,
      extras: {
        'youtubeId': s.youtubeId,
        'localPath': s.localPath,
        'songId': s.id,
      },
    );
  }

  Future<void> _playIndex(int i) async {
    if (i < 0 || i >= _songs.length) return;
    _index = i;
    final s = _songs[i];
    mediaItem.add(_toMediaItem(s));
    unawaited(_syncHomeWidget(s));
    _segments = await _sponsor.getSegments(s.youtubeId);
    try {
      final uri = s.isLocal
          ? Uri.file(s.localPath!)
          : await _yt.getBestAudioUri(s.youtubeId);
      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.play();
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
    await _cache.recordPlay(
      models.PlayHistoryEntry(songId: s.id, playedAt: DateTime.now()),
    );
    _broadcast(_player.playbackEvent);
  }

  void _prefetchNext() {
    if (_songs.length < 2) return;
    final next = (_index + 1) % _songs.length;
    final s = _songs[next];
    if (s.isLocal) return;
    scheduleMicrotask(() async {
      try {
        await _yt.getBestAudioUri(s.youtubeId);
      } catch (_) {}
    });
  }

  AudioProcessingState _mapProcessing(ProcessingState s) {
    switch (s) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _broadcast(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessing(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _index,
        repeatMode: _repeat,
      ),
    );
  }

  void _onPosition(Duration pos) {
    if (_segments.isEmpty) return;
    for (final seg in _segments) {
      if (pos >= seg.start && pos < seg.end) {
        _player.seek(seg.end);
        break;
      }
    }
    if (_crossfadeSeconds > 0 &&
        _player.duration != null &&
        _player.duration! - pos <= Duration(seconds: _crossfadeSeconds)) {
      // Dual-player crossfade not implemented.
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_songs.isEmpty) return;
    if (_repeat == AudioServiceRepeatMode.one) {
      await _player.seek(Duration.zero);
      return;
    }
    var next = _index + 1;
    if (next >= _songs.length) {
      if (_repeat == AudioServiceRepeatMode.all) {
        next = 0;
      } else {
        await _player.pause();
        return;
      }
    }
    await _playIndex(next);
    _prefetchNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_songs.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    var prev = _index - 1;
    if (prev < 0) {
      prev = _repeat == AudioServiceRepeatMode.all ? _songs.length - 1 : 0;
    }
    await _playIndex(prev);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.all && _songs.length > 1) {
      final cur = _songs[_index];
      _songs.shuffle();
      _index = _songs.indexWhere((e) => e.id == cur.id);
      if (_index < 0) _index = 0;
      queue.add(_songs.map(_toMediaItem).toList());
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeat = repeatMode;
    _broadcast(_player.playbackEvent);
  }

  Future<void> setCrossfadeSeconds(int s) async {
    _crossfadeSeconds = s.clamp(0, 12);
  }

  Future<void> setSleepTimer(Duration? d) async {
    _sleepTimer?.cancel();
    if (d == null) return;
    _sleepTimer = Timer(d, () async {
      await _player.pause();
    });
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _songs.length ||
        newIndex < 0 ||
        newIndex >= _songs.length) {
      return;
    }
    final item = _songs.removeAt(oldIndex);
    _songs.insert(newIndex, item);
    if (oldIndex == _index) {
      _index = newIndex;
    } else if (oldIndex < _index && newIndex >= _index) {
      _index--;
    } else if (oldIndex > _index && newIndex <= _index) {
      _index++;
    }
    queue.add(_songs.map(_toMediaItem).toList());
    mediaItem.add(_toMediaItem(_songs[_index]));
  }

  Future<void> addToQueue(Song song) async {
    _songs.add(song);
    queue.add(_songs.map(_toMediaItem).toList());
  }

  Future<void> removeFromQueueAt(int index) async {
    if (index < 0 || index >= _songs.length) return;
    _songs.removeAt(index);
    if (_index >= _songs.length) _index = _songs.length - 1;
    queue.add(_songs.map(_toMediaItem).toList());
    if (_songs.isEmpty) {
      mediaItem.add(null);
      await _player.stop();
    } else {
      await _playIndex(_index.clamp(0, _songs.length - 1));
    }
  }

  Song? get currentSong =>
      _songs.isEmpty ? null : _songs[_index.clamp(0, _songs.length - 1)];

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  Future<void> _syncHomeWidget(Song s) async {
    try {
      await HomeWidget.saveWidgetData<String>('title', s.title);
      await HomeWidget.saveWidgetData<String>('artist', s.artist);
      await HomeWidget.updateWidget(androidName: 'XoqsHomeWidget');
    } catch (_) {}
  }
}
