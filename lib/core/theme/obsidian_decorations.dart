import 'dart:ui';

import 'package:flutter/material.dart';

import 'obsidian_colors.dart';

/// Card radius per Stitch (16px).
abstract final class ObsidianRadii {
  static const card = 16.0;
  static const sm = 12.0;
}

/// Glass mini player decoration (blur applied via [BackdropFilter] in widget).
BoxDecoration miniPlayerDecoration() {
  return BoxDecoration(
    color: ObsidianColors.surfaceContainerHigh.withValues(alpha: 0.6),
    borderRadius: BorderRadius.circular(ObsidianRadii.card),
    border: Border.all(
      color: ObsidianColors.outlineVariant.withValues(alpha: 0.12),
    ),
    boxShadow: [
      BoxShadow(
        color: ObsidianColors.primary.withValues(alpha: 0.04),
        blurRadius: 24,
        spreadRadius: 0,
      ),
    ],
  );
}

Widget obsidianGlass({required Widget child, BorderRadius? radius}) {
  final r = radius ?? BorderRadius.circular(ObsidianRadii.card);
  return ClipRRect(
    borderRadius: r,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: child,
    ),
  );
}
