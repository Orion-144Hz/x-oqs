import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'obsidian_colors.dart';

TextTheme buildObsidianTextTheme(TextTheme base) {
  final display = GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w800,
      fontSize: 40,
      height: 1.05,
      color: ObsidianColors.primaryText,
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w800,
      fontSize: 32,
      height: 1.1,
      color: ObsidianColors.primaryText,
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 1.15,
      color: ObsidianColors.primaryText,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: ObsidianColors.primaryText,
    ),
  );

  final manrope = GoogleFonts.manropeTextTheme(display);
  return manrope.copyWith(
    bodyLarge: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: ObsidianColors.primaryText,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: ObsidianColors.secondaryText,
    ),
    bodySmall: GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: ObsidianColors.secondaryText,
    ),
    labelLarge: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: ObsidianColors.primaryText,
    ),
    labelMedium: GoogleFonts.manrope(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: ObsidianColors.secondaryText,
    ),
  );
}
