import 'package:equatable/equatable.dart';

class StreamUrlEntry extends Equatable {
  const StreamUrlEntry({
    required this.youtubeId,
    required this.url,
    required this.expiresAt,
    this.qualityLabel,
  });

  final String youtubeId;
  final String url;
  final DateTime expiresAt;
  final String? qualityLabel;

  bool get isValid => DateTime.now().isBefore(expiresAt);

  @override
  List<Object?> get props => [youtubeId, url, expiresAt];
}
