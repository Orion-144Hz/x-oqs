import 'package:equatable/equatable.dart';

class Song extends Equatable {
  const Song({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.artist,
    this.album = '',
    this.thumbnailUrl,
    this.duration = Duration.zero,
    this.localPath,
    this.isLiked = false,
    this.isDownloaded = false,
    this.lastPlayedAt,
    this.genreTags = const [],
  });

  final String id;
  final String youtubeId;
  final String title;
  final String artist;
  final String album;
  final String? thumbnailUrl;
  final Duration duration;
  final String? localPath;
  final bool isLiked;
  final bool isDownloaded;
  final DateTime? lastPlayedAt;
  final List<String> genreTags;

  bool get isLocal => localPath != null && localPath!.isNotEmpty;

  Song copyWith({
    String? id,
    String? youtubeId,
    String? title,
    String? artist,
    String? album,
    String? thumbnailUrl,
    Duration? duration,
    String? localPath,
    bool? isLiked,
    bool? isDownloaded,
    DateTime? lastPlayedAt,
    List<String>? genreTags,
  }) {
    return Song(
      id: id ?? this.id,
      youtubeId: youtubeId ?? this.youtubeId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      localPath: localPath ?? this.localPath,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      genreTags: genreTags ?? this.genreTags,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'youtubeId': youtubeId,
        'title': title,
        'artist': artist,
        'album': album,
        'thumbnailUrl': thumbnailUrl,
        'durationSec': duration.inSeconds,
        'localPath': localPath,
        'isLiked': isLiked ? 1 : 0,
        'isDownloaded': isDownloaded ? 1 : 0,
        'lastPlayedAt': lastPlayedAt?.millisecondsSinceEpoch,
      };

  factory Song.fromJson(Map<String, Object?> m) {
    return Song(
      id: m['id']! as String,
      youtubeId: m['youtubeId']! as String,
      title: m['title']! as String,
      artist: m['artist']! as String,
      album: (m['album'] as String?) ?? '',
      thumbnailUrl: m['thumbnailUrl'] as String?,
      duration: Duration(seconds: (m['durationSec'] as int?) ?? 0),
      localPath: m['localPath'] as String?,
      isLiked: (m['isLiked'] as int? ?? 0) == 1,
      isDownloaded: (m['isDownloaded'] as int? ?? 0) == 1,
      lastPlayedAt: (m['lastPlayedAt'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(m['lastPlayedAt']! as int)
          : null,
    );
  }

  factory Song.fromMap(Map<String, Object?> m) => Song.fromJson(m);

  @override
  List<Object?> get props => [id, youtubeId, title, artist, localPath, isLiked];
}
