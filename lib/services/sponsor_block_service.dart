import 'package:dio/dio.dart';
import 'package:x_oqs/core/network/dio_client.dart';
import 'package:x_oqs/shared/models/sponsor_segment.dart';

class SponsorBlockService {
  SponsorBlockService({Dio? dio}) : _dio = dio ?? createSponsorBlockDio();

  final Dio _dio;

  Future<List<SponsorSegment>> getSegments(String youtubeId) async {
    try {
      final res = await _dio.get<dynamic>(
        '/skipSegments',
        queryParameters: {
          'videoID': youtubeId,
          'categories': '["sponsor","intro","outro","selfpromo"]',
        },
      );
      final data = res.data;
      if (data is! List) return [];
      return data.map((e) {
        final m = e as Map<String, dynamic>;
        final seg = m['segment'] as List<dynamic>;
        return SponsorSegment(
          category: m['category'] as String? ?? 'sponsor',
          start: Duration(milliseconds: ((seg[0] as num) * 1000).round()),
          end: Duration(milliseconds: ((seg[1] as num) * 1000).round()),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  bool shouldSkipAt(Duration position, List<SponsorSegment> segments) {
    for (final s in segments) {
      if (position >= s.start && position < s.end) return true;
    }
    return false;
  }
}
