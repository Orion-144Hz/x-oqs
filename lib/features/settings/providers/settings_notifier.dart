import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_oqs/core/constants/app_constants.dart';

class AppSettings {
  const AppSettings({
    required this.streamKbps,
    required this.downloadKbps,
    required this.storageLimitBytes,
    required this.useDynamicTheme,
    required this.localeCode,
    required this.lastFmKey,
  });

  final int? streamKbps;
  final int downloadKbps;
  final int storageLimitBytes;
  final bool useDynamicTheme;
  final String localeCode;
  final String lastFmKey;

  AppSettings copyWith({
    int? streamKbps,
    bool clearStreamKbps = false,
    int? downloadKbps,
    int? storageLimitBytes,
    bool? useDynamicTheme,
    String? localeCode,
    String? lastFmKey,
  }) {
    return AppSettings(
      streamKbps: clearStreamKbps ? null : (streamKbps ?? this.streamKbps),
      downloadKbps: downloadKbps ?? this.downloadKbps,
      storageLimitBytes: storageLimitBytes ?? this.storageLimitBytes,
      useDynamicTheme: useDynamicTheme ?? this.useDynamicTheme,
      localeCode: localeCode ?? this.localeCode,
      lastFmKey: lastFmKey ?? this.lastFmKey,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _kStream = 'settings_stream_kbps';
  static const _kDownload = 'settings_download_kbps';
  static const _kStorage = 'settings_storage_limit_bytes';
  static const _kDynamic = 'settings_dynamic_theme';
  static const _kLocale = 'settings_locale';
  static const _kLastFm = 'settings_lastfm_key';

  @override
  Future<AppSettings> build() async {
    final p = await SharedPreferences.getInstance();
    return _read(p);
  }

  AppSettings _read(SharedPreferences p) {
    return AppSettings(
      streamKbps: p.getInt(_kStream),
      downloadKbps: p.getInt(_kDownload) ?? 256,
      storageLimitBytes:
          p.getInt(_kStorage) ?? AppConstants.defaultStorageLimitBytes,
      useDynamicTheme: p.getBool(_kDynamic) ?? false,
      localeCode: p.getString(_kLocale) ?? 'en',
      lastFmKey: p.getString(_kLastFm) ?? '',
    );
  }

  Future<void> _persistAndRefresh(Future<void> Function(SharedPreferences p) fn) async {
    final p = await SharedPreferences.getInstance();
    await fn(p);
    state = AsyncValue.data(_read(p));
  }

  Future<void> setStreamKbps(int? kbps) async {
    await _persistAndRefresh((p) async {
      if (kbps == null) {
        await p.remove(_kStream);
      } else {
        await p.setInt(_kStream, kbps);
      }
    });
  }

  Future<void> setDownloadKbps(int kbps) async {
    await _persistAndRefresh((p) => p.setInt(_kDownload, kbps));
  }

  Future<void> setStorageLimitBytes(int bytes) async {
    await _persistAndRefresh((p) => p.setInt(_kStorage, bytes));
  }

  Future<void> setDynamicTheme(bool v) async {
    await _persistAndRefresh((p) => p.setBool(_kDynamic, v));
  }

  Future<void> setLocaleCode(String code) async {
    await _persistAndRefresh((p) => p.setString(_kLocale, code));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
