import 'package:dio/dio.dart';
import 'package:x_oqs/core/network/dio_client.dart';

class LyricLine {
  LyricLine({required this.time, required this.text});

  final Duration time;
  final String text;
}

class LyricDocument {
  LyricDocument({required this.lines, this.plain});

  final List<LyricLine> lines;
  final String? plain;
}

/// LRCLIB (no auth).
class LyricsService {
  LyricsService({Dio? dio}) : _dio = dio ?? createLrclibDio();

  final Dio _dio;

  Future<LyricDocument?> fetchLyrics({
    required String artist,
    required String title,
    Duration? duration,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/search',
        queryParameters: {
          'artist_name': artist,
          'track_name': title,
          if (duration != null) 'duration': duration.inSeconds,
        },
      );
      final raw = res.data;
      if (raw is! List || raw.isEmpty) return null;
      final first = raw.first as Map<String, dynamic>;
      final synced = first['syncedLyrics'] as String?;
      final plain = first['plainLyrics'] as String?;
      if (synced != null && synced.trim().isNotEmpty) {
        return LyricDocument(lines: _parseLrc(synced), plain: plain);
      }
      if (plain != null && plain.trim().isNotEmpty) {
        return LyricDocument(
          lines: plain
              .split('\n')
              .map((e) => LyricLine(time: Duration.zero, text: e))
              .toList(),
          plain: plain,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<LyricLine> _parseLrc(String raw) {
    final lines = <LyricLine>[];
    final re = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');
    for (final line in raw.split('\n')) {
      final m = re.firstMatch(line.trim());
      if (m == null) continue;
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final frac = m.group(3)!;
      final cent = int.tryParse(frac.padRight(3, '0').substring(0, 3)) ?? 0;
      final t = Duration(minutes: min, seconds: sec, milliseconds: cent ~/ 10);
      lines.add(LyricLine(time: t, text: m.group(4)!.trim()));
    }
    return lines;
  }
}
