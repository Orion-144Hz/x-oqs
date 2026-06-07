import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ObsidianColors.surfaceContainer,
      borderRadius: BorderRadius.circular(ObsidianRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(ObsidianRadii.card),
        onTap: onTap,
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ObsidianRadii.card),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: ObsidianColors.surfaceContainerHigh,
                          child: const Icon(
                            Icons.queue_music,
                            size: 48,
                            color: ObsidianColors.secondaryText,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
