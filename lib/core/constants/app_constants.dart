/// App-wide constants (debounce, cache TTL, defaults).
abstract final class AppConstants {
  static const searchDebounceMs = 300;
  static const streamUrlTtl = Duration(hours: 5);
  static const searchCacheTtl = Duration(hours: 24);
  static const recentlyPlayedLimit = 50;
  static const defaultStorageLimitBytes = 1024 * 1024 * 1024; // 1 GB
  static const minStorageLimitBytes = 1024 * 1024 * 1024;
  static const maxStorageLimitBytes = 50 * 1024 * 1024 * 1024;
  static const spotifyRedirectScheme = 'x-oqs';
  static const spotifyRedirectHost = 'spotify-callback';
  static const spotifyRedirectUri = '$spotifyRedirectScheme://$spotifyRedirectHost';
}
