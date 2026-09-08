import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';

// -----------------------------------------------------------------------
// Shared vertical map pin — round head, pointed tail. Used anywhere a
// location needs marking (group-ride pins, destination flags, and any
// future map screen) so every pin on every map reads as one consistent
// family instead of a mix of circles/badges/icons.
//
// Pulled out of live_ride_screen.dart (was private, _MapPin) once a
// second screen (paused/rest-stop) needed the same pins — anything shown
// on more than one map screen belongs here rather than duplicated per
// screen.
//
// Typically rendered once into a style image and shown as a native
// MapLibre Symbol with iconAnchor: 'bottom', since the tail's tip — not
// the widget's geometric center — is what needs to line up with the real
// geo point. See widgets that use this for that wiring.
//
// These pins are never rotated to counter the map's heading — a vertical
// pin should stay upright on screen no matter which way the map is
// currently facing, the same way Google Maps/Waze keep POI pins upright
// and reserve rotation for a direction-arrow marker alone.
// -----------------------------------------------------------------------

class MapPin extends StatelessWidget {
  final Color color;
  final double headDiameter;
  final Widget? child;

  const MapPin({super.key, required this.color, this.headDiameter = 34, this.child});

  @override
  Widget build(BuildContext context) {
    final tailHeight = headDiameter * 0.42;
    return SizedBox(
      width: headDiameter,
      height: headDiameter + tailHeight,
      child: CustomPaint(
        painter: MapPinPainter(color: color, headDiameter: headDiameter),
        child: child == null
            ? null
            : Padding(
                padding: EdgeInsets.only(bottom: tailHeight),
                child: Center(child: child),
              ),
      ),
    );
  }
}

class MapPinPainter extends CustomPainter {
  final Color color;
  final double headDiameter;

  MapPinPainter({required this.color, required this.headDiameter});

  @override
  void paint(Canvas canvas, Size size) {
    final r = headDiameter / 2;
    final headCenter = Offset(size.width / 2, r);
    final tip = Offset(size.width / 2, size.height);

    // Tail: a triangle from two points on the head's circle down to the
    // tip, half-angle chosen so the triangle's base sits flush with the
    // circle rather than overlapping or leaving a gap.
    const halfAngleDeg = 35.0;
    final rad = halfAngleDeg * math.pi / 180;
    final left = headCenter + Offset(-r * math.sin(rad), r * math.cos(rad));
    final right = headCenter + Offset(r * math.sin(rad), r * math.cos(rad));

    final pin = Path.combine(
      PathOperation.union,
      Path()..addOval(Rect.fromCircle(center: headCenter, radius: r)),
      Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
    );

    // Soft drop shadow, offset down slightly, so the pin reads as sitting
    // above the map rather than flat against it.
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(
      pin,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();

    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawPath(
      pin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant MapPinPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.headDiameter != headDiameter;
}

// -----------------------------------------------------------------------
// Group-ride pins — a MapPin with a rider's initials in its head.
// -----------------------------------------------------------------------

class RiderPin extends StatelessWidget {
  final String initials;
  final Color color;

  const RiderPin({super.key, required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return MapPin(
      color: color,
      headDiameter: 32,
      child: Text(initials,
          style: AppText.mono(size: 10, weight: FontWeight.w700, color: Colors.white)),
    );
  }
}
