import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _access = 'spotify_access_token';
  static const _refresh = 'spotify_refresh_token';
  static const _expiry = 'spotify_expiry_ms';

  Future<void> saveSpotifyTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    await _s.write(key: _access, value: accessToken);
    await _s.write(key: _refresh, value: refreshToken);
    await _s.write(
      key: _expiry,
      value: expiresAt.millisecondsSinceEpoch.toString(),
    );
  }

  Future<String?> getAccessToken() => _s.read(key: _access);

  Future<String?> getRefreshToken() => _s.read(key: _refresh);

  Future<DateTime?> getAccessExpiry() async {
    final v = await _s.read(key: _expiry);
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(v));
  }

  Future<void> clearSpotify() async {
    await _s.delete(key: _access);
    await _s.delete(key: _refresh);
    await _s.delete(key: _expiry);
  }
}
