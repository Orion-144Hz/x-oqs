import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    this.description = '',
    this.coverUrl,
    this.trackIds = const [],
    this.isSpotifyImport = false,
    this.spotifyId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String? coverUrl;
  final List<String> trackIds;
  final bool isSpotifyImport;
  final String? spotifyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    List<String>? trackIds,
    bool? isSpotifyImport,
    String? spotifyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      trackIds: trackIds ?? this.trackIds,
      isSpotifyImport: isSpotifyImport ?? this.isSpotifyImport,
      spotifyId: spotifyId ?? this.spotifyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, trackIds, isSpotifyImport, spotifyId];
}
