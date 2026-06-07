import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/features/artist/presentation/artist_screen.dart';
import 'package:x_oqs/features/download/presentation/download_manager_sheet.dart';
import 'package:x_oqs/features/home/presentation/home_screen.dart';
import 'package:x_oqs/features/library/presentation/library_screen.dart';
import 'package:x_oqs/features/player/presentation/now_playing_screen.dart';
import 'package:x_oqs/features/playlist/presentation/playlist_detail_screen.dart';
import 'package:x_oqs/features/search/presentation/search_screen.dart';
import 'package:x_oqs/features/settings/presentation/settings_screen.dart';
import 'package:x_oqs/features/spotify_import/presentation/spotify_import_wizard.dart';
import 'package:x_oqs/features/spotify_import/presentation/unmatched_tracks_screen.dart';
import 'package:x_oqs/shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Route bulunamadı: ${state.uri}\n${state.error ?? ''}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: LibraryScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (c, s) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (c, s) => const NowPlayingScreen(),
      ),
      GoRoute(
        path: '/playlist/:id',
        builder: (c, s) => PlaylistDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/artist/:id',
        builder: (c, s) => ArtistScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/import/spotify',
        builder: (c, s) => const SpotifyImportWizard(),
      ),
      GoRoute(
        path: '/import/spotify/unmatched',
        builder: (c, s) => const UnmatchedTracksScreen(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (c, s) => const DownloadManagerScreen(),
      ),
    ],
  );
}
