import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/audio/audio_handler.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    required this.handler,
    required this.playing,
    super.key,
  });

  final XoqsAudioHandler handler;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final song = handler.currentSong;
    if (song == null) return const SizedBox.shrink();

    return PlayerGlassShell(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ObsidianRadii.card),
          onTap: () => context.push('/player'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: miniPlayerDecoration(),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: song.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnailUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: ObsidianColors.surfaceContainerHigh,
                          child: const Icon(Icons.music_note, color: ObsidianColors.secondaryText),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (playing) {
                      handler.pause();
                    } else {
                      handler.play();
                    }
                  },
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: ObsidianColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerGlassShell extends StatelessWidget {
  const PlayerGlassShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return obsidianGlass(
      radius: BorderRadius.circular(ObsidianRadii.card),
      child: child,
    );
  }
}
