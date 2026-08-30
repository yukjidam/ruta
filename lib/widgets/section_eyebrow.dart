import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Small mono "eyebrow" label with a dash — used above headings
/// throughout the auth and ride-planning screens.
class SectionEyebrow extends StatelessWidget {
  final String text;
  final Color color;

  const SectionEyebrow({super.key, required this.text, this.color = AppColors.route});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 2, color: color),
        const SizedBox(width: 8),
        Text(text.toUpperCase(), style: AppText.mono(size: 11, color: color, letterSpacing: 2)),
      ],
    );
  }
}
