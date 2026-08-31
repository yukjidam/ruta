import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Positions [child] at a screen-pixel coordinate, sized to [width]x[height]
/// and anchored per [anchor] (defaults to centering the box on the point,
/// matching flutter_map's default marker alignment).
///
/// maplibre_gl's map is a native platform view, not a Flutter canvas, so —
/// unlike flutter_map's MarkerLayer — there's no way to anchor an arbitrary
/// Flutter widget (text, gradients, custom icons) to a lat/lng directly.
/// The standard workaround: convert each marker's lat/lng to a screen-pixel
/// offset via MapLibreMapController.toScreenLocation()/
/// toScreenLocationBatch(), then lay ordinary Flutter widgets on top of the
/// map in a Stack, refreshing those offsets whenever the camera moves
/// (typically from the map's onCameraIdle callback).
///
/// Renders nothing until a screen point is available, to avoid a flash at
/// the Stack's top-left corner before the first screen-position lookup
/// completes.
class ScreenMarker extends StatelessWidget {
  final math.Point<double>? point;
  final double width;
  final double height;
  final Alignment anchor;
  final Widget child;

  const ScreenMarker({
    super.key,
    required this.point,
    required this.width,
    required this.height,
    required this.child,
    this.anchor = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final p = point;
    if (p == null) return const SizedBox.shrink();
    // Alignment.x/y run -1..1 (left/top to right/bottom) — convert to a
    // 0..1 fraction of the box that sits to the left of / above the point,
    // e.g. Alignment.bottomCenter (0, 1) -> fx=0.5, fy=1.0, so the point
    // sits at the bottom-center of the box (the box appears above the
    // point) — same idea as flutter_map's Marker(alignment: ...).
    final fx = (anchor.x + 1) / 2;
    final fy = (anchor.y + 1) / 2;
    return Positioned(
      left: p.x - width * fx,
      top: p.y - height * fy,
      width: width,
      height: height,
      child: child,
    );
  }
}
