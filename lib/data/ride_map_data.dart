import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Shared between every screen that draws the ride's map (live ride, paused/
// rest-stop, and any future screen) — the route, the crew's positions, and
// the marker palette all need to agree across screens, so they live here
// once instead of being redefined (and risking drift) per screen.
// ---------------------------------------------------------------------------

// Free, open vector basemap — no API key, no account, no usage cap.
// "Positron" is the light, low-contrast style (pale streets, soft green
// parks). OpenFreeMap doesn't ship an official dark preset, so the
// dark/asphalt look on each screen is achieved with a themed scrim +
// vignette drawn over the map, plus theme-colored route/markers, rather
// than a style swap here. If a true dark basemap is wanted later, the real
// fix is a self-hosted custom style JSON (openfreemap.org).
const mapStyleUrl = 'https://tiles.openfreemap.org/styles/positron';

// Route line: the theme's literal "route" gold, cased in an asphalt shade
// so it reads as a lane cut into the dark chrome — Waze-style outline, but
// drawn from AppColors instead of an unrelated purple.
const routeLineColor = AppColors.route;
const routeShadowColor = AppColors.asphalt3;

// "You are here" marker. Uses `success` (green) rather than `route` (gold)
// so your own position never gets confused with the gold route line or the
// gold-colored group-ride pin.
const liveMarkerColor = AppColors.success;

// Destination flag / turn-sign chip.
const turnSignColor = AppColors.rust;

// Dummy positions along Aguinaldo Hwy — swap for Supabase Realtime
// broadcast positions once Phase 8 wires up real GPS.
const groupPositions = [
  LatLng(14.2635, 120.8755),
  LatLng(14.2600, 120.8790),
  LatLng(14.2580, 120.8810),
];

// Dummy route-ahead path. Swap for the real ORS polyline response once
// Phase 10 (routing engine) is wired up.
const routePoints = [
  LatLng(14.2615, 120.8775),
  LatLng(14.2609, 120.8768),
  LatLng(14.2598, 120.8756),
  LatLng(14.2582, 120.8745),
  LatLng(14.2561, 120.8738),
  LatLng(14.2538, 120.8737),
  LatLng(14.2516, 120.8744),
];

/// Compass bearing (0–360°) from [from] to [to]. MapLibre's
/// `CameraPosition.bearing` is defined as "the compass direction that is
/// up" — this is the plain heading-up formula, no flip needed.
double bearingDegrees(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;

  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final bearingRad = math.atan2(y, x);
  return (bearingRad * 180 / math.pi + 360) % 360;
}

/// maplibre_gl's line/circle annotation options take colors as hex strings
/// rather than Flutter Color objects — this converts one, dropping the
/// alpha channel (annotations use a separate opacity field if needed).
String colorToHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
