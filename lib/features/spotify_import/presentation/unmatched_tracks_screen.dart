import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/services/spotify_import_service.dart';

class UnmatchedTracksScreen extends ConsumerWidget {
  const UnmatchedTracksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(spotifyImportServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Unmatched tracks')),
      body: FutureBuilder<List<UnmatchedTrack>>(
        future: svc.getUnmatched(),
        builder: (context, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No unmatched items in this session.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final t = list[i];
              return ListTile(
                tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                title: Text('${t.artist} — ${t.title}'),
                subtitle: Text(t.spotifyUri),
              );
            },
          );
        },
      ),
    );
  }
}
