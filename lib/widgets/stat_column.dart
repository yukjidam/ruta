import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// A single "value over label" stat, mono-spaced like an odometer readout.
/// Reused in the garage, live ride bottom bar, and ride summary.
class StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Color labelColor;

  const StatColumn({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = AppColors.route,
    this.labelColor = AppColors.inkDim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.mono(size: 16, weight: FontWeight.w700, color: valueColor)),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppText.mono(size: 9.5, color: labelColor, letterSpacing: 1),
        ),
      ],
    );
  }
}
