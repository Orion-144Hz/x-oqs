import 'package:flutter/material.dart';

/// Obsidian Stage design tokens.
abstract final class ObsidianColors {
  static const background = Color(0xFF0e0e0e);
  static const surfaceContainerLowest = Color(0xFF000000);
  static const surfaceContainerLow = Color(0xFF131313);
  static const surfaceContainer = Color(0xFF191919);
  static const surfaceContainerHigh = Color(0xFF1f1f1f);
  static const surfaceContainerHighest = Color(0xFF262626);
  static const primary = Color(0xFF72fe8f);
  static const primaryContainer = Color(0xFF1cb853);
  static const primaryText = Color(0xFFffffff);
  static const secondaryText = Color(0xFFababab);
  static const outlineVariant = Color(0xFF484848);
  static const onPrimary = Color(0xFF005f26);

  static Color ghostBorder(BuildContext context) =>
      outlineVariant.withValues(alpha: 0.15);

  /// Mini player glass: surface high @ 60%.
  static Color miniPlayerGlass(BuildContext context) =>
      surfaceContainerHigh.withValues(alpha: 0.6);
}
