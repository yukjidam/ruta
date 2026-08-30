import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum AppButtonVariant { primary, outline, danger }

/// Shared button used across every screen so the three actions
/// (go / cancel / destructive) always look and behave the same way.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final BoxBorder? border;

    switch (variant) {
      case AppButtonVariant.primary:
        background = AppColors.route;
        foreground = AppColors.darkInk;
        border = null;
        break;
      case AppButtonVariant.outline:
        background = Colors.transparent;
        foreground = AppColors.ink;
        border = Border.all(color: AppColors.inkDim, width: 1.4);
        break;
      case AppButtonVariant.danger:
        background = AppColors.rust;
        foreground = AppColors.ink;
        border = null;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: border,
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: AppText.body(weight: FontWeight.w700, color: foreground)
                      .copyWith(letterSpacing: 0.5, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
