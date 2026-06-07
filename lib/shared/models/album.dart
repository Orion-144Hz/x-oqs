import 'package:equatable/equatable.dart';

class Album extends Equatable {
  const Album({
    required this.id,
    required this.title,
    required this.artistName,
    this.coverUrl,
    this.year,
    this.trackIds = const [],
  });

  final String id;
  final String title;
  final String artistName;
  final String? coverUrl;
  final int? year;
  final List<String> trackIds;

  @override
  List<Object?> get props => [id, title, artistName, trackIds];
}
