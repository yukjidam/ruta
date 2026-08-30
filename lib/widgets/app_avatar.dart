import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Circular initials avatar. Used for riders everywhere — feed, crew,
/// lobby, live map pins — so a rider's color stays recognizable app-wide.
class AppAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  final Color textColor;
  final Color borderColor;

  const AppAvatar({
    super.key,
    required this.initials,
    this.color = AppColors.pine,
    this.size = 36,
    this.textColor = AppColors.darkInk,
    this.borderColor = AppColors.asphalt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppText.mono(
          size: size * 0.32,
          weight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
