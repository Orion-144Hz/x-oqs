import 'package:equatable/equatable.dart';

class PlayHistoryEntry extends Equatable {
  const PlayHistoryEntry({
    required this.songId,
    required this.playedAt,
    this.listenDuration = Duration.zero,
  });

  final String songId;
  final DateTime playedAt;
  final Duration listenDuration;

  @override
  List<Object?> get props => [songId, playedAt, listenDuration];
}
