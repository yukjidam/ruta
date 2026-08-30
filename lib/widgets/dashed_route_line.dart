import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's signature motif: a dashed "route line" — the literal GPS
/// path — reused on the map, in the feed, and stitching together the
/// start/end pins of a ride summary.
class DashedRouteLine extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double gapWidth;

  const DashedRouteLine({
    super.key,
    this.color = AppColors.route,
    this.height = 2,
    this.dashWidth = 8,
    this.gapWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(height),
      painter: _DashedLinePainter(color: color, dashWidth: dashWidth, gapWidth: gapWidth),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double gapWidth;

  _DashedLinePainter({required this.color, required this.dashWidth, required this.gapWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
