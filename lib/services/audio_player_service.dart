import 'package:audio_service/audio_service.dart';
import 'package:x_oqs/core/audio/audio_handler.dart';
import 'package:x_oqs/shared/models/song.dart';

/// Facade over [XoqsAudioHandler] for features/player.
class AudioPlayerService {
  AudioPlayerService(this._handler);

  final XoqsAudioHandler _handler;

  Future<void> loadQueue(List<Song> songs, {int initialIndex = 0}) =>
      _handler.loadQueue(songs, initialIndex: initialIndex);

  Future<void> play() => _handler.play();

  Future<void> pause() => _handler.pause();

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> skipToNext() => _handler.skipToNext();

  Future<void> skipToPrevious() => _handler.skipToPrevious();

  Future<void> setShuffleMode(AudioServiceShuffleMode mode) =>
      _handler.setShuffleMode(mode);

  Future<void> setRepeatMode(AudioServiceRepeatMode mode) =>
      _handler.setRepeatMode(mode);

  Future<void> setCrossfadeSeconds(int s) => _handler.setCrossfadeSeconds(s);

  Future<void> setSleepTimer(Duration? d) => _handler.setSleepTimer(d);

  Future<void> reorderQueue(int oldIndex, int newIndex) =>
      _handler.reorderQueue(oldIndex, newIndex);

  Future<void> addToQueue(Song song) => _handler.addToQueue(song);

  Future<void> removeFromQueueAt(int index) =>
      _handler.removeFromQueueAt(index);

  Song? get currentSong => _handler.currentSong;

  Stream<PlaybackState> get playbackState => _handler.playbackState;

  Stream<Duration> get position => _handler.positionStream;

  List<Song> get queueSongs => _handler.songs;
}
