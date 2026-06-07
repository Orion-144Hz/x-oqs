import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';
import 'package:x_oqs/shared/models/song.dart';

class SongRow extends StatelessWidget {
  const SongRow({
    required this.song,
    this.onTap,
    this.downloadProgress,
    this.trailing,
    super.key,
  });

  final Song song;
  final VoidCallback? onTap;
  final double? downloadProgress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ObsidianRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                    if (downloadProgress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: downloadProgress,
                            minHeight: 4,
                            backgroundColor:
                                ObsidianColors.outlineVariant.withValues(alpha: 0.3),
                            color: ObsidianColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
