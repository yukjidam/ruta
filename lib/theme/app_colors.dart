import 'package:flutter/material.dart';

/// Color tokens lifted directly from the UI/UX design pass.
/// Dark "asphalt" tones = on-the-road screens (map, live tracking, auth).
/// Warm "paper" tones = in-the-logbook screens (feed, ride summary).
class AppColors {
  AppColors._();

  static const asphalt = Color(0xFF17171A);
  static const asphalt2 = Color(0xFF232226);
  static const asphalt3 = Color(0xFF2E2D31);

  static const paper = Color(0xFFF3ECDD);
  static const paper2 = Color(0xFFEBE2CC);
  static const paperLine = Color(0xFFD9CBA9);

  static const route = Color(0xFFF5B700);
  static const routeDim = Color(0xFF8C6E1B);
  static const rust = Color(0xFFC1502E);
  static const pine = Color(0xFF3B5A45);

  static const ink = Color(0xFFF5F1E8);
  static const inkDim = Color(0xFFA9A69F);
  static const darkInk = Color(0xFF1B1B1D);
  static const darkInkDim = Color(0xFF6B6558);

  static const success = Color(0xFF6FBE8C);
}
