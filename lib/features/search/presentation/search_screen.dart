import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/constants/app_constants.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';
import 'package:x_oqs/services/audio_player_service.dart';
import 'package:x_oqs/shared/models/song.dart';
import 'package:x_oqs/shared/widgets/category_tile.dart';
import 'package:x_oqs/shared/widgets/song_row.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _q = '';
  Future<List<Song>>? _future;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String raw) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () async {
        if (!mounted) return;
        final t = raw.trim();
        if (t.isEmpty) {
          setState(() {
            _q = '';
            _future = null;
          });
          return;
        }
        setState(() {
          _q = t;
          _future = ref.read(youtubeProvider).search(t).then((p) => p.songs);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioPlayerServiceProvider);
    final categories = [
      ('Pop', const Color(0xFF6b2d7a)),
      ('Rock', const Color(0xFF3d2f5c)),
      ('Hip-Hop', const Color(0xFF2d4a3e)),
      ('Indie', const Color(0xFF4a3f2d)),
      ('Dance', const Color(0xFF1f4a5c)),
      ('Podcasts', const Color(0xFF5c3a2a)),
      ('Electronic', const Color(0xFF234a3a)),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text('Search', style: Theme.of(context).textTheme.displaySmall),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _controller,
              onChanged: _scheduleSearch,
              style: const TextStyle(color: ObsidianColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Artists, songs, or podcasts',
                filled: true,
                fillColor: ObsidianColors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ObsidianRadii.card),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ObsidianRadii.card),
                  borderSide: BorderSide(
                    color: ObsidianColors.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(Icons.search, color: ObsidianColors.secondaryText),
              ),
            ),
          ),
        ),
        if (_future == null) ...[
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildBuilderDelegate(
                (c, i) {
                  final cat = categories[i];
                  return CategoryTile(
                    label: cat.$1,
                    color: cat.$2,
                    onTap: () {
                      _controller.text = cat.$1;
                      _scheduleSearch(cat.$1);
                    },
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
        ] else
          SliverToBoxAdapter(
            child: FutureBuilder<List<Song>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${snap.error}', style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                final songs = snap.data ?? [];
                if (songs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No results for “$_q”.', style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
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
              },
            ),
          ),
      ],
    );
  }
}
