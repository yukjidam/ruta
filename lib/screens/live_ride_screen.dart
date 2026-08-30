import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/ruta_map_layers.dart';

// ---------------------------------------------------------------------------
// Visual palette for this screen only. Kept local (not promoted to
// AppColors) since this is a prototype re-skin — move these into the shared
// theme once the look is signed off.
// ---------------------------------------------------------------------------

// Route line: vivid purple-blue with a darker outline so it pops against a
// light basemap, Waze-style.
const _routeLineColor = Color(0xFF7C5CFC);
const _routeShadowColor = Color(0xFF3A2A7A);

// "You are here" puck.
const _navArrowCyan = Color(0xFF00E1D9);

// Top instruction header.
const _headerBlack = Color(0xFF15151B);

// Current-street pill, same family as the route line so the two read as
// "one system" at a glance.
const _streetPillPurple = Color(0xFF6E4CF0);

// Hazard icon + upcoming-hazard panel accents.
const _hazardYellow = Color(0xFFFFC53D);

// Music FAB.
const _musicPink = Color(0xFFFF3D81);

// Speedometer dial + metallic-looking outer ring.
const _speedoDial = Color(0xFF1A1A1F);
const _speedoRing = [Color(0xFFD8D8DE), Color(0xFF6B6B72), Color(0xFF232327)];

// Dummy positions along Aguinaldo Hwy — swap for Supabase Realtime
// broadcast positions once Phase 8 wires up real GPS. The rider's own
// position now lives in _LiveRideScreenState._livePosition instead of a
// fixed constant, since it needs to move.
const _groupPositions = [
  LatLng(14.2635, 120.8755),
  LatLng(14.2600, 120.8790),
  LatLng(14.2580, 120.8810),
];

// Dummy route-ahead path, roughly matching the turn card's "turn right onto
// Jefferson Avenue, then continue". Swap for the real ORS polyline response
// once Phase 10 (routing engine) is wired up.
const _routePoints = [
  LatLng(14.2615, 120.8775),
  LatLng(14.2609, 120.8768),
  LatLng(14.2598, 120.8756),
  LatLng(14.2582, 120.8745),
  LatLng(14.2561, 120.8738),
  LatLng(14.2538, 120.8737),
  LatLng(14.2516, 120.8744),
];

// Dummy turn-by-turn / trip / hazard copy — all swap for real routing +
// telemetry data once Phase 8 (GPS) and Phase 10 (routing engine) land.
// Kept as simple constants for now so the layout is easy to re-point later.
const _turnDistance = '700 m';
const _upcomingStreet = 'Jefferson Avenue';
const _currentStreet = 'John St.';
const _currentSpeedKmh = 60;
const _hazardText = 'Speed bumps in 500 m';
const _tripSummary = '48 min  •  10:29  •  12 mi';
const _tripProgress = 0.42;

/// Compass bearing (0–360°) from [from] to [to]. Drives the heading-up
/// rotation — recalculated on every simulated step below so the map keeps
/// facing the direction of travel instead of rotating once and freezing.
/// Swap the simulation for a real GPS/heading stream once Phase 8 lands;
/// this function itself stays the same.
double _bearingDegrees(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;

  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final bearingRad = math.atan2(y, x);
  return (bearingRad * 180 / math.pi + 360) % 360;
}

// Initial heading only, so the map opens already facing the right way
// instead of snapping into rotation after the first frame. Negated because
// flutter_map's rotation runs opposite to compass bearing — without the
// flip the map turned away from the road instead of facing it. After the
// first frame, _LiveRideScreenState's simulation timer takes over and
// recalculates this on every step.
final double _headingDeg = -_bearingDegrees(_routePoints[0], _routePoints[1]);

// How often the simulated rider advances to the next route point. Purely a
// demo cadence — replace with the real position-stream callback cadence
// once GPS is wired up.
const _simStepInterval = Duration(milliseconds: 1400);

class LiveRideScreen extends StatefulWidget {
  const LiveRideScreen({super.key});

  @override
  State<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends State<LiveRideScreen> {
  final MapController _mapController = MapController();

  // Live "you are here" state. Starts at the first route point and steps
  // forward along _routePoints on a timer to fake movement. Once Phase 8
  // wires up real GPS, replace the timer with the position-stream listener
  // and feed each fix into this same state — the rotation logic underneath
  // doesn't need to change.
  LatLng _livePosition = _routePoints.first;
  double _liveHeadingDeg = _headingDeg;
  int _routeIndex = 0;
  Timer? _simTimer;

  // True while the camera is heading-locked (the normal nav state).
  // Flipped off by _resetNorth() and back on by _recenter(), same pattern
  // as Waze/Google Maps' compass button.
  bool _headingLocked = true;

  @override
  void initState() {
    super.initState();
    _simTimer = Timer.periodic(_simStepInterval, (_) => _advanceSimulatedPosition());
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  // Steps the rider one point further along the dummy route, recomputes the
  // bearing to the *next* point, and — if heading-lock is on — rotates the
  // map to match. This is what keeps the map "always pointing the
  // direction the rider should go" instead of rotating once at load and
  // freezing.
  void _advanceSimulatedPosition() {
    if (_routeIndex >= _routePoints.length - 1) {
      // Loop back to the start so the demo keeps running. A real position
      // stream simply wouldn't fire once the ride ends.
      _routeIndex = 0;
    }
    final from = _routePoints[_routeIndex];
    final to = _routePoints[_routeIndex + 1];
    final newHeading = -_bearingDegrees(from, to);

    setState(() {
      _livePosition = from;
      _liveHeadingDeg = newHeading;
      _routeIndex++;
    });

    if (_headingLocked) {
      final currentZoom = _mapController.camera.zoom;
      _mapController.moveAndRotate(_livePosition, currentZoom, _liveHeadingDeg);
    }
  }

  // Recentres on "my" position and heading, and re-engages heading-lock if
  // the rider had panned away or hit "north up".
  void _recenter() {
    _headingLocked = true;
    _mapController.moveAndRotate(_livePosition, 15.5, _liveHeadingDeg);
  }

  // Nav apps that lock rotation to heading still give you a way back to
  // north-up — this is that escape hatch. Also disengages heading-lock so
  // the simulation loop stops fighting the user's view until they tap
  // _recenter() again.
  void _resetNorth() {
    _headingLocked = false;
    _mapController.rotate(0);
  }

  // Placeholder handlers for the two new chrome buttons this redesign
  // adds. Neither wires up to a real feature yet — replace with the
  // actual voice-command / now-playing flows when those land.
  void _onMicTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice control — coming soon'), duration: Duration(seconds: 1)),
    );
  }

  void _onMusicTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Music controls — coming soon'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: Stack(
        children: [
          // ---------------------------------------------------------------
          // MAP LAYER
          // ---------------------------------------------------------------
          // Waze-style forward tilt. Only the map layer tilts — every
          // overlay below (header, pills, panels, buttons) stays flat on
          // screen. flutter_map has no native camera pitch (it's a flat 2D
          // renderer), so this fakes perspective with a Matrix4 transform.
          // Tradeoffs worth knowing about:
          //  - pins and the route line tilt along with the tiles, so round
          //    badges read as slightly oval rather than circular
          //  - street labels baked into the OSM tile images distort too
          //    (there's no way to keep just those upright without
          //    switching to vector tiles)
          //  - panning near the top of the tilted view moves the map
          //    further than panning near the bottom, since perspective
          //    foreshortens that area — a known quirk of this technique,
          //    not a bug
          ClipRect(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(0.5), // ~29° forward pitch
              child: OverflowBox(
                maxHeight: double.infinity,
                child: SizedBox(
                  // Oversized so the perspective shrink doesn't leave a
                  // visible gap above the "horizon".
                  width: screenSize.width,
                  height: screenSize.height * 1.8,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(14.2620, 120.8770),
                      initialZoom: 15.5,
                      // Heading-up, like Waze: the map faces your
                      // direction of travel instead of true north. Manual
                      // rotate is disabled since rotation is
                      // heading-locked — _resetNorth() is the way back to
                      // north-up.
                      initialRotation: _headingDeg,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      // NOTE: the basemap's own colors (off-white streets,
                      // pale green parks, gray road lines) come from
                      // whatever tile provider/style RutaMapLayers.tileLayer()
                      // points at — that lives in widgets/ruta_map_layers.dart
                      // and isn't touched by this redesign. If it's still
                      // pointed at a default OSM raster style, swap it for
                      // a light vector style (e.g. a "Positron"-style
                      // MapTiler/Stadia layer) to fully match the
                      // reference look.
                      RutaMapLayers.tileLayer(),
                      // Route-ahead outline: a darker purple casing line
                      // for contrast against a light basemap, with the
                      // brighter purple-blue route color drawn on top.
                      // Swap _routePoints for the real ORS polyline once
                      // Phase 10 lands.
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 12,
                            color: _routeShadowColor,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 7,
                            color: _routeLineColor,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _routePoints.last,
                            width: 26,
                            height: 26,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.flag_circle, color: _routeLineColor, size: 26),
                          ),
                          Marker(
                            point: _livePosition,
                            width: 54,
                            height: 54,
                            // Always points straight up. Since the map
                            // itself rotates to match _liveHeadingDeg on
                            // every simulated step (see
                            // _advanceSimulatedPosition above), "up on
                            // screen" always means "the direction you're
                            // currently facing" — no separate rotation
                            // needed here, in the demo or with real GPS.
                            child: const _HeadingArrow(),
                          ),
                          Marker(
                            point: _groupPositions[0],
                            width: 34,
                            height: 34,
                            child: const _RiderPin(initials: 'JM', color: AppColors.route),
                          ),
                          Marker(
                            point: _groupPositions[1],
                            width: 34,
                            height: 34,
                            child: const _RiderPin(initials: 'KR', color: AppColors.pine),
                          ),
                          Marker(
                            point: _groupPositions[2],
                            width: 34,
                            height: 34,
                            child: const _RiderPin(initials: 'MT', color: AppColors.rust),
                          ),
                        ],
                      ),
                      RutaMapLayers.attribution(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // TOP INSTRUCTION HEADER — full-bleed dark bar, rounded bottom
          // corners, big turn icon + distance + upcoming street name.
          // ---------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopInstructionHeader(
              distance: _turnDistance,
              streetName: _upcomingStreet,
            ),
          ),

          // ---------------------------------------------------------------
          // RIGHT-SIDE CONTROLS — mic + music near the top, recenter
          // (large) and the north-reset escape hatch stacked near the
          // bottom, clear of the hazard panel.
          // ---------------------------------------------------------------
          Positioned(
            right: 16,
            top: topInset + 118,
            child: Column(
              children: [
                _CircleButton(
                  icon: Icons.mic_none_rounded,
                  background: AppColors.asphalt2,
                  iconColor: AppColors.ink,
                  onTap: _onMicTap,
                ),
                const SizedBox(height: 12),
                _CircleButton(
                  icon: Icons.music_note_rounded,
                  background: _musicPink,
                  iconColor: Colors.white,
                  onTap: _onMusicTap,
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: screenSize.height * 0.30,
            child: Column(
              children: [
                _CircleButton(
                  icon: Icons.explore_outlined,
                  background: AppColors.asphalt2,
                  iconColor: AppColors.ink,
                  size: 42,
                  iconSize: 19,
                  onTap: _resetNorth,
                ),
                const SizedBox(height: 12),
                _CircleButton(
                  icon: Icons.navigation_rounded,
                  background: _navArrowCyan,
                  iconColor: Colors.black,
                  size: 60,
                  iconSize: 26,
                  onTap: _recenter,
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // BOTTOM STACK — current-street pill, trip summary, hazard
          // panel, then the existing ride-control actions underneath.
          // ---------------------------------------------------------------
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  const _StreetPill(label: _currentStreet),
                  const SizedBox(height: 10),
                  const _SpeedAndHazardRow(),
                  const SizedBox(height: 12),
                  const _RideActionBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Top instruction header
// -----------------------------------------------------------------------

class _TopInstructionHeader extends StatelessWidget {
  final String distance;
  final String streetName;

  const _TopInstructionHeader({required this.distance, required this.streetName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _headerBlack,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Row(
            children: [
              // Dummy turn icon — swap for the routing engine's actual
              // maneuver type (left/right/roundabout/merge/...) once
              // Phase 10 lands.
              const Icon(Icons.turn_right_rounded, color: Colors.white, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        distance,
                        style: AppText.body(size: 36, weight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 17, weight: FontWeight.w700, color: _navArrowCyan),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Current-street pill
// -----------------------------------------------------------------------

class _StreetPill extends StatelessWidget {
  final String label;
  const _StreetPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: _streetPillPurple,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Text(
          label,
          style: AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Speedometer (bottom-left) + trip summary / hazard panel (rest of width)
// -----------------------------------------------------------------------

class _SpeedAndHazardRow extends StatelessWidget {
  const _SpeedAndHazardRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _Speedometer(speedKmh: _currentSpeedKmh),
        const SizedBox(width: 12),
        const Expanded(child: _HazardPanel()),
      ],
    );
  }
}

class _Speedometer extends StatelessWidget {
  final int speedKmh;
  const _Speedometer({required this.speedKmh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _speedoRing,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _speedoDial),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$speedKmh',
                style: AppText.mono(size: 27, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
            Text('km/h',
                style: AppText.mono(size: 9, weight: FontWeight.w600, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _HazardPanel extends StatelessWidget {
  const _HazardPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trip summary sits above the panel itself, over the map — a
        // translucent dark pill keeps it legible against any tile color.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _tripSummary,
            style: AppText.mono(size: 11, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thin progress bar flush with the panel's top edge.
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: LinearProgressIndicator(
                    value: _tripProgress,
                    minHeight: 4,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation(_routeLineColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _hazardYellow.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.warning_rounded, color: _hazardYellow, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _hazardText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                              size: 14.5, weight: FontWeight.w800, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------
// Ride action bar — unchanged behavior (pause / rest stop / end ride),
// lightly restyled to sit under the new white hazard panel.
// -----------------------------------------------------------------------

class _RideActionBar extends StatelessWidget {
  const _RideActionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.asphalt2,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.asphalt3,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.asphalt3),
            ),
            child: IconButton(
              icon: const Icon(Icons.pause, color: AppColors.ink, size: 20),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.pausedRide),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.pausedRide),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.inkDim),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Rest stop', style: AppText.body(size: 13, weight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.captureMemory),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rust,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('End ride',
                  style: AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Small shared circular FAB used for the map's floating controls.
// -----------------------------------------------------------------------

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _CircleButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.size = 48,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Group-ride avatar pins
// -----------------------------------------------------------------------

class _RiderPin extends StatelessWidget {
  final String initials;
  final Color color;

  const _RiderPin({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: AppText.mono(size: 10, weight: FontWeight.w700, color: AppColors.darkInk)),
    );
  }
}

/// The "you are here, facing this way" puck — a soft cyan glow behind a
/// white halo (for contrast against the map in any lighting) with a bold
/// cyan directional arrow. Always points straight up: the map itself
/// rotates to heading, so "up" already means "the way you're facing".
class _HeadingArrow extends StatelessWidget {
  const _HeadingArrow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft glow ring — purely decorative, gives the puck a "live GPS
        // signal" feel like Waze/Google Maps' pulsing blue dot.
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _navArrowCyan.withOpacity(0.22)),
        ),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: _navArrowCyan, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: const Icon(Icons.navigation_rounded, color: _navArrowCyan, size: 24),
        ),
      ],
    );
  }
}
