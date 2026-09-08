import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Themed overlay so the light OpenFreeMap tiles read as part of the app's
/// dark "asphalt" system instead of a bright rectangle dropped behind the
/// chrome. Shared by every map screen (live ride, paused/rest-stop, and any
/// future one) so they all read as the same map, just framed differently.
///
/// [topOpacity]/[bottomOpacity] let each screen tune how much darkening its
/// own top/bottom chrome needs — e.g. the live-ride screen's full-bleed nav
/// header and bottom trip panel need more contrast than the paused screen's
/// map, which only has a small stats overlay up top and hands off to a
/// solid panel (not more map) at the bottom.
class MapScrim extends StatelessWidget {
  final double topOpacity;
  final double bottomOpacity;

  const MapScrim({super.key, this.topOpacity = 0.55, this.bottomOpacity = 0.65});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Top-and-bottom gradient: darkest right behind whatever chrome
        // sits at each edge, fully transparent through the middle so the
        // route line and markers stay clearly readable.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.asphalt.withOpacity(topOpacity),
                Colors.transparent,
                Colors.transparent,
                AppColors.asphalt.withOpacity(bottomOpacity),
              ],
              stops: const [0.0, 0.25, 0.6, 1.0],
            ),
          ),
        ),
        // Soft radial vignette at the edges — the classic nav-app trick
        // that pulls the eye toward the route/markers instead of the raw
        // tile edges.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [Colors.transparent, AppColors.asphalt.withOpacity(0.35)],
              stops: const [0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
