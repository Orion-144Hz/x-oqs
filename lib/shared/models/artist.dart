import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  const Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isFollowed = false,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final bool isFollowed;

  @override
  List<Object?> get props => [id, name, isFollowed];
}
