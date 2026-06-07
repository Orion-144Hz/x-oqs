import 'package:equatable/equatable.dart';

class SponsorSegment extends Equatable {
  const SponsorSegment({
    required this.category,
    required this.start,
    required this.end,
  });

  final String category;
  final Duration start;
  final Duration end;

  @override
  List<Object?> get props => [category, start, end];
}
