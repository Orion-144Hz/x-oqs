import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';
import 'package:x_oqs/features/player/presentation/lyrics_view.dart';
import 'package:x_oqs/features/player/presentation/queue_sheet.dart';
import 'package:x_oqs/services/lyrics_service.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  var _lyricsOpen = false;

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final lyrics = ref.watch(lyricsProvider);
    final cache = ref.watch(cacheProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.expand_more_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_lyricsOpen ? Icons.lyrics : Icons.lyrics_outlined),
            onPressed: () => setState(() => _lyricsOpen = !_lyricsOpen),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music_outlined),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: ObsidianColors.surfaceContainerLow,
              builder: (_) => QueueSheet(handler: handler),
            ),
          ),
        ],
      ),
      body: StreamBuilder<PlaybackState>(
        stream: handler.playbackState,
        builder: (context, snap) {
          final song = handler.currentSong;
          if (song == null) {
            return const Center(child: Text('Nothing playing'));
          }
          final st = snap.data;
          final playing = st?.playing ?? false;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 32),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(ObsidianRadii.card),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: song.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(color: ObsidianColors.surfaceContainerHigh),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22),
                          ),
                          Text(song.artist, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    FutureBuilder(
                      future: cache.getSong(song.id),
                      builder: (context, snap) {
                        final liked = snap.data?.isLiked ?? song.isLiked;
                        return IconButton(
                          onPressed: () async {
                            await cache.setLiked(song.id, !liked);
                            await cache.upsertSongs([
                              song.copyWith(isLiked: !liked),
                            ]);
                            if (context.mounted) setState(() {});
                          },
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked
                                ? ObsidianColors.primary
                                : ObsidianColors.secondaryText,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<Duration>(
                  stream: handler.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final dur = song.duration;
                    return Column(
                      children: [
                        Slider(
                          value: dur.inMilliseconds == 0
                              ? 0
                              : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
                          onChanged: (v) {
                            final target = Duration(
                              milliseconds: (v * dur.inMilliseconds).round(),
                            );
                            handler.seek(target);
                          },
                          activeColor: ObsidianColors.primary,
                          inactiveColor: ObsidianColors.outlineVariant.withValues(alpha: 0.35),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos), style: Theme.of(context).textTheme.bodySmall),
                              Text(_fmt(dur), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 36,
                      onPressed: handler.skipToPrevious,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    IconButton(
                      iconSize: 56,
                      onPressed: () {
                        if (playing) {
                          handler.pause();
                        } else {
                          handler.play();
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: ObsidianColors.primary,
                        foregroundColor: ObsidianColors.onPrimary,
                      ),
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                    IconButton(
                      iconSize: 36,
                      onPressed: handler.skipToNext,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
                if (_lyricsOpen) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: LyricsPanel(
                      lyrics: lyrics,
                      artist: song.artist,
                      title: song.title,
                      duration: song.duration,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
