import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Three-role type system from the design pass:
/// - Anton   -> display/headings, road-sign energy
/// - Work Sans -> body copy
/// - JetBrains Mono -> anything that reads like data (distance, time, ETA)
class AppText {
  AppText._();

  static TextStyle display({double size = 32, Color color = AppColors.ink}) {
    return GoogleFonts.anton(
      fontSize: size,
      color: color,
      letterSpacing: 0.5,
      height: 0.95,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
  }) {
    return GoogleFonts.workSans(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.inkDim,
    double letterSpacing = 1,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
