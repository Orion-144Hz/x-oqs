import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/constants/app_constants.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/services/spotify_import_service.dart';

class SpotifyImportWizard extends ConsumerStatefulWidget {
  const SpotifyImportWizard({super.key});

  @override
  ConsumerState<SpotifyImportWizard> createState() => _SpotifyImportWizardState();
}

class _SpotifyImportWizardState extends ConsumerState<SpotifyImportWizard> {
  String? _status;
  Stream<ImportProgress>? _progress;

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(spotifyImportServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import from Spotify')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uses PKCE (no client secret). Set SPOTIFY_CLIENT_ID with --dart-define and add redirect URI ${AppConstants.spotifyRedirectUri} in Spotify Dashboard.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                setState(() => _status = 'Opening Spotify…');
                try {
                  await svc.startPkceLogin();
                  setState(() => _status = 'Authorized. Fetch library next.');
                } catch (e) {
                  setState(() => _status = 'Error: $e');
                }
              },
              child: const Text('Connect Spotify'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                setState(() => _status = 'Fetching…');
                try {
                  final snap = await svc.fetchFullLibrary();
                  setState(() {
                    _status = 'Importing…';
                    _progress = svc.importLibrary(snap);
                  });
                } catch (e) {
                  setState(() => _status = 'Error: $e');
                }
              },
              child: const Text('Fetch & import library'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/import/spotify/unmatched'),
              child: const Text('View unmatched tracks'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(_status!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (_progress != null)
              Expanded(
                child: StreamBuilder<ImportProgress>(
                  stream: _progress,
                  builder: (context, snap) {
                    final p = snap.data;
                    if (p == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          '${p.phase}: ${p.done}/${p.total} — matched ${p.matched}, unmatched ${p.unmatched}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: p.total == 0 ? null : p.done / p.total,
                          color: ObsidianColors.primary,
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
