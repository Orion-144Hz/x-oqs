import 'package:flutter/material.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';

class StorageMeter extends StatelessWidget {
  const StorageMeter({
    required this.usedBytes,
    required this.limitBytes,
    super.key,
  });

  final int usedBytes;
  final int limitBytes;

  @override
  Widget build(BuildContext context) {
    final ratio = limitBytes <= 0 ? 0.0 : (usedBytes / limitBytes).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Storage',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              '${_gb(usedBytes)} / ${_gb(limitBytes)} GB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: ObsidianColors.surfaceContainerHigh,
            color: ObsidianColors.primary,
          ),
        ),
      ],
    );
  }

  String _gb(int bytes) {
    final g = bytes / (1024 * 1024 * 1024);
    return g.toStringAsFixed(1);
  }
}
