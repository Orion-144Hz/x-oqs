import 'package:flutter/material.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';

class SpotifyImportBadge extends StatelessWidget {
  const SpotifyImportBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ObsidianColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ObsidianColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        'IMPORTED FROM SPOTIFY',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ObsidianColors.primary,
              letterSpacing: 1.4,
              fontSize: 9,
            ),
      ),
    );
  }
}
