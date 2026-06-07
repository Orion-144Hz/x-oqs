import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';
import 'package:x_oqs/services/audio_player_service.dart';
import 'package:x_oqs/shared/models/song.dart';
import 'package:x_oqs/shared/widgets/playlist_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<ConnectivityResult> _net = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((v) {
      if (mounted) setState(() => _net = v);
    });
    _connSub = Connectivity().onConnectivityChanged.listen((v) {
      if (mounted) setState(() => _net = v);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  bool get _offline =>
      _net.isEmpty ||
      _net.every((e) => e == ConnectivityResult.none);

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(cacheProvider);
    final rec = ref.watch(recommendationServiceProvider);
    final audio = ref.watch(audioPlayerServiceProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          toolbarHeight: 64,
          backgroundColor: ObsidianColors.surfaceContainerLowest.withValues(alpha: 0.4),
          title: Text(
            'X-oqS',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24),
          ),
          actions: [
            if (_offline)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.offline_pin, color: ObsidianColors.secondaryText, size: 20),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: ObsidianColors.secondaryText),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              _greeting(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder(
              future: cache.getRecentlyPlayed(limit: 6),
              builder: (context, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Text(
                    'Play something — your recently played grid will fill in.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (c, i) {
                    final s = items[i];
                    return Material(
                      color: ObsidianColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(ObsidianRadii.card),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(ObsidianRadii.card),
                        onTap: () => _playSingle(audio, s),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: s.thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: s.thumbnailUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: ObsidianColors.surfaceContainerHigh,
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: ObsidianColors.surfaceContainerHigh,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Text('Picked for you', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ObsidianColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ObsidianColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'AI',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: ObsidianColors.primary,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: FutureBuilder(
              future: rec.getPickedForYou(limit: 8),
              builder: (context, snap) {
                final songs = snap.data ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: songs.isEmpty ? 3 : songs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (c, i) {
                    if (songs.isEmpty) {
                      return PlaylistCard(
                        title: ['Daily Mix 1', 'Release Radar', 'Discover Weekly'][i],
                        subtitle: 'Based on your listening',
                        onTap: () {},
                      );
                    }
                    final s = songs[i];
                    return PlaylistCard(
                      title: s.title,
                      subtitle: s.artist,
                      imageUrl: s.thumbnailUrl,
                      onTap: () => _playSingle(audio, s),
                    );
                  },
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('Featured Playlists', style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: FutureBuilder(
              future: cache.getPlaylists(),
              builder: (context, snap) {
                final pls = snap.data ?? [];
                if (pls.isEmpty) {
                  return Text(
                    'Create playlists from Library — they appear here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: pls
                      .take(4)
                      .map(
                        (p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.name),
                          subtitle: Text('${p.trackIds.length} tracks'),
                          onTap: () => context.push('/playlist/${p.id}'),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _playSingle(AudioPlayerService audio, Song s) async {
    await audio.loadQueue([s], initialIndex: 0);
    await audio.play();
  }
}
