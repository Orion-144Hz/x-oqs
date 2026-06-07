import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_oqs/core/audio/audio_handler.dart';
import 'package:x_oqs/core/network/dio_client.dart';
import 'package:x_oqs/core/storage/secure_token_store.dart';
import 'package:x_oqs/core/storage/storage_quota_manager.dart';
import 'package:x_oqs/services/audio_player_service.dart';
import 'package:x_oqs/services/cache_service.dart';
import 'package:x_oqs/services/download_service.dart';
import 'package:x_oqs/services/lyrics_service.dart';
import 'package:x_oqs/services/recommendation_service.dart';
import 'package:x_oqs/services/sponsor_block_service.dart';
import 'package:x_oqs/services/spotify_import_service.dart';
import 'package:x_oqs/services/youtube_music_service.dart';

final cacheProvider = Provider<CacheService>(
  (ref) => throw UnimplementedError('cacheProvider: override in main'),
);

final youtubeProvider = Provider<YoutubeMusicService>(
  (ref) => throw UnimplementedError('youtubeProvider: override in main'),
);

final sponsorBlockProvider = Provider<SponsorBlockService>(
  (ref) => SponsorBlockService(),
);

final lyricsProvider = Provider<LyricsService>((ref) => LyricsService());

final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => SecureTokenStore(),
);

final dioProvider = Provider<Dio>((ref) => createDio());

final storageQuotaProvider = Provider<StorageQuotaManager>(
  (ref) => StorageQuotaManager(ref.watch(cacheProvider)),
);

final downloadServiceProvider = Provider<DownloadService>(
  (ref) => DownloadService(
    ref.watch(cacheProvider),
    ref.watch(youtubeProvider),
    ref.watch(dioProvider),
    ref.watch(storageQuotaProvider),
  ),
);

final recommendationServiceProvider = Provider<RecommendationService>(
  (ref) => RecommendationService(ref.watch(cacheProvider)),
);

const spotifyClientId = String.fromEnvironment('SPOTIFY_CLIENT_ID', defaultValue: '');

final spotifyImportServiceProvider = Provider<SpotifyImportService>(
  (ref) => SpotifyImportService(
    ref.watch(secureTokenStoreProvider),
    ref.watch(youtubeProvider),
    ref.watch(cacheProvider),
    dio: ref.watch(dioProvider),
    clientId: spotifyClientId,
  ),
);

final audioHandlerProvider = Provider<XoqsAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider: override in main'),
);

final audioPlayerServiceProvider = Provider<AudioPlayerService>(
  (ref) => AudioPlayerService(ref.watch(audioHandlerProvider)),
);
