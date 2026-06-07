import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/services/audio_player_service.dart';
import 'package:x_oqs/shared/models/song.dart';
import 'package:x_oqs/shared/widgets/song_row.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(cacheProvider);
    final audio = ref.watch(audioPlayerServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text('Your Library', style: Theme.of(context).textTheme.displaySmall),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: ObsidianColors.primary,
          labelColor: ObsidianColors.primaryText,
          unselectedLabelColor: ObsidianColors.secondaryText,
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Liked'),
            Tab(text: 'Downloaded'),
            Tab(text: 'Artists'),
            Tab(text: 'Albums'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              FutureBuilder(
                future: cache.getPlaylists(),
                builder: (context, snap) {
                  final pls = snap.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                    itemCount: pls.length,
                    itemBuilder: (ctx, i) {
                      final p = pls[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('${p.trackIds.length} tracks'),
                        onTap: () => context.push('/playlist/${p.id}'),
                      );
                    },
                  );
                },
              ),
              FutureBuilder(
                future: cache.getLikedSongs(),
                builder: (context, snap) => _songList(snap.data ?? [], audio, context),
              ),
              FutureBuilder(
                future: cache.getDownloadedSongs(),
                builder: (context, snap) => _songList(snap.data ?? [], audio, context),
              ),
              FutureBuilder(
                future: cache.getFollowedArtists(),
                builder: (context, snap) {
                  final list = snap.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final a = list[i];
                      return ListTile(
                        title: Text(a.name),
                        onTap: () => context.push('/artist/${a.id}'),
                      );
                    },
                  );
                },
              ),
              FutureBuilder(
                future: cache.getSavedAlbums(),
                builder: (context, snap) {
                  final list = snap.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final a = list[i];
                      return ListTile(
                        title: Text(a.title),
                        subtitle: Text(a.artistName),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _songList(List<Song> songs, AudioPlayerService audio, BuildContext context) {
    if (songs.isEmpty) {
      return Center(
        child: Text('Nothing here yet.', style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
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
    );
  }
}
