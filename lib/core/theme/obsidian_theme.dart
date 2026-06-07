import 'package:flutter/material.dart';

import 'obsidian_colors.dart';
import 'obsidian_text_theme.dart';

ThemeData buildObsidianTheme({bool useDynamicGreen = false}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ObsidianColors.background,
  );
  final textTheme = buildObsidianTextTheme(base.textTheme);
  final seed = useDynamicGreen ? ObsidianColors.primary : ObsidianColors.primary;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    surface: ObsidianColors.surfaceContainer,
    primary: ObsidianColors.primary,
    onPrimary: ObsidianColors.onPrimary,
    secondary: ObsidianColors.primaryContainer,
    onSecondary: ObsidianColors.primaryText,
    error: const Color(0xFFff7351),
  ).copyWith(
    surfaceContainerLowest: ObsidianColors.surfaceContainerLowest,
    surfaceContainerLow: ObsidianColors.surfaceContainerLow,
    surfaceContainer: ObsidianColors.surfaceContainer,
    surfaceContainerHigh: ObsidianColors.surfaceContainerHigh,
    surfaceContainerHighest: ObsidianColors.surfaceContainerHighest,
    onSurface: ObsidianColors.primaryText,
    onSurfaceVariant: ObsidianColors.secondaryText,
    outlineVariant: ObsidianColors.outlineVariant,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: ObsidianColors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Colors.transparent),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ObsidianColors.surfaceContainerLowest.withValues(
        alpha: 0.85,
      ),
      indicatorColor: ObsidianColors.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium!.copyWith(color: ObsidianColors.secondaryText),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? ObsidianColors.primary : ObsidianColors.secondaryText,
          size: 24,
        );
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: ObsidianColors.primary,
      inactiveTrackColor: ObsidianColors.outlineVariant.withValues(alpha: 0.4),
      thumbColor: ObsidianColors.primary,
      overlayColor: ObsidianColors.primary.withValues(alpha: 0.2),
    ),
  );
}
