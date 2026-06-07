import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';

class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(cacheProvider);
    return FutureBuilder(
      future: cache.getArtist(id),
      builder: (context, snap) {
        final artist = snap.data;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(artist?.name ?? 'Artist'),
                  background: Container(
                    color: ObsidianColors.surfaceContainerLow,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Channel-linked popular tracks and albums can extend this page. Spotify id: $id',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
