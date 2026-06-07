import 'dart:io';

import 'package:x_oqs/services/cache_service.dart';

class StorageQuotaManager {
  StorageQuotaManager(this._cache);

  final CacheService _cache;

  Future<int> directoryBytes(Directory dir) async {
    var total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> enforceLimit({
    required int maxBytes,
    required Directory downloadsRoot,
  }) async {
    int sizeOf(String path) {
      final f = File(path);
      if (!f.existsSync()) return 0;
      try {
        return f.lengthSync();
      } catch (_) {
        return 0;
      }
    }

    Future<void> deleteFile(String path) async {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }

    await _cache.evictLRUUntilUnderBytes(
      maxBytes,
      fileSize: sizeOf,
      deleteFile: deleteFile,
    );
  }
}
