import 'dart:math';

import 'package:x_oqs/services/cache_service.dart';
import 'package:x_oqs/shared/models/song.dart';

class MoodProfile {
  MoodProfile({required this.energy, required this.diversity});

  final double energy;
  final double diversity;
}

/// Phase-1 local recommendations from play history.
class RecommendationService {
  RecommendationService(this._cache);

  final CacheService _cache;

  Future<List<Song>> getPickedForYou({int limit = 12}) async {
    final recent = await _cache.getRecentlyPlayed(limit: 30);
    if (recent.isEmpty) return [];
    final rnd = Random();
    final pool = recent.toList()..shuffle(rnd);
    return pool.take(limit).toList();
  }

  Future<List<Song>> getDailyMixes({int count = 3}) async {
    final recent = await _cache.getRecentlyPlayed(limit: 40);
    if (recent.isEmpty) return [];
    final out = <Song>[];
    final rnd = Random(42);
    for (var i = 0; i < count; i++) {
      final shuffled = recent.toList()..shuffle(rnd);
      out.addAll(shuffled.take(4));
    }
    return out.take(count * 4).toList();
  }

  Future<List<Song>> suggestAutoQueueTail({required Song seed, int n = 10}) async {
    final recent = await _cache.getRecentlyPlayed(limit: 50);
    final others = recent.where((s) => s.id != seed.id).toList()..shuffle(Random());
    return others.take(n).toList();
  }

  Future<MoodProfile> analyzeMood() async {
    final recent = await _cache.getRecentlyPlayed(limit: 20);
    final energy = recent.isEmpty ? 0.5 : 0.5 + (recent.length / 40).clamp(0, 0.5);
    return MoodProfile(energy: energy, diversity: 0.6);
  }
}
