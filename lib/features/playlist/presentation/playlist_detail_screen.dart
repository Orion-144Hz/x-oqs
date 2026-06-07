import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';
import 'package:x_oqs/features/settings/providers/settings_notifier.dart';
import 'package:x_oqs/services/audio_player_service.dart';
import 'package:x_oqs/shared/widgets/spotify_import_badge.dart';
import 'package:x_oqs/shared/widgets/song_row.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(cacheProvider);
    final audio = ref.watch(audioPlayerServiceProvider);
    final settings = ref.watch(settingsProvider);

    return FutureBuilder(
      future: cache.getPlaylist(id),
      builder: (context, snap) {
        final pl = snap.data;
        if (pl == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Playlist not found')),
          );
        }
        return FutureBuilder(
          future: cache.getSongsByIds(pl.trackIds),
          builder: (context, songSnap) {
            final songs = songSnap.data ?? [];
            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(pl.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ObsidianColors.surfaceContainerHigh,
                              ObsidianColors.background,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pl.isSpotifyImport) const SpotifyImportBadge(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () async {
                                  if (songs.isEmpty) return;
                                  await audio.loadQueue(songs, initialIndex: 0);
                                  await audio.play();
                                  if (context.mounted) context.push('/player');
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Play'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  if (songs.isEmpty) return;
                                  final shuffled = List.of(songs)..shuffle();
                                  await audio.loadQueue(shuffled, initialIndex: 0);
                                  await audio.play();
                                  if (context.mounted) context.push('/player');
                                },
                                child: const Text('Shuffle'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  final dl = ref.read(downloadServiceProvider);
                                  final limit = settings.valueOrNull?.storageLimitBytes;
                                  for (final s in songs) {
                                    await dl.enqueue(
                                      s,
                                      kbps: settings.valueOrNull?.downloadKbps ?? 256,
                                      storageLimitBytes: limit,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.download_outlined),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: songs.length,
                    itemBuilder: (c, i) {
                      final s = songs[i];
                      return SongRow(
                        song: s,
                        onTap: () async {
                          await audio.loadQueue(songs, initialIndex: i);
                          await audio.play();
                          if (context.mounted) context.push('/player');
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
