import 'package:equatable/equatable.dart';

enum DownloadJobStatus {
  queued,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadJob extends Equatable {
  const DownloadJob({
    required this.id,
    required this.songId,
    required this.status,
    required this.progress,
    required this.qualityKbps,
    required this.targetPath,
    this.errorMessage,
  });

  final String id;
  final String songId;
  final DownloadJobStatus status;
  final double progress;
  final int qualityKbps;
  final String targetPath;
  final String? errorMessage;

  @override
  List<Object?> get props => [id, songId, status, progress];
}
