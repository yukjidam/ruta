import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../data/ride_map_data.dart';
import '../utils/widget_image_capture.dart';
import '../widgets/map_pin.dart';
import '../widgets/map_scrim.dart';

// ---------------------------------------------------------------------------
// Visual palette for this screen, now pulled from the shared AppColors/
// AppText tokens instead of one-off hex values, so the live-ride screen
// reads as part of the same app as everything else instead of its own
// prototype skin.
//
// The route/marker colors, basemap style URL, dummy route/crew positions,
// and the colorToHex/bearingDegrees helpers used to live here too, but now
// live in ../data/ride_map_data.dart — the paused/rest-stop screen's map
// needs the exact same route and crew positions, so anything shared across
// map screens belongs there instead of being redefined per screen.
// ---------------------------------------------------------------------------

// Top instruction header + turn-sign chip.
const _headerColor = AppColors.asphalt;

// Music FAB — was an off-brand pink, now the theme's pine accent.
const _musicColor = AppColors.pine;

// Speedometer dial + progress arc.
const _speedoDial = AppColors.asphalt;
const _speedoTrack = AppColors.asphalt3;
const _speedoArc = AppColors.route;

// Camera pitch (0 = straight down, 60 = MapLibre's usual max) for the
// Waze-style forward tilt. This is a REAL 3D camera angle now, handled
// natively by MapLibre — it replaces the old Matrix4/rotateX perspective
// hack entirely, which is what was causing the warped "upside down" look
// near the top of the screen (far-away content was being pushed past the
// safe range of that fake-perspective math). Tune 0–60 to taste.
const _cameraTilt = 50.0;

// Dummy turn-by-turn / trip copy — all swap for real routing +
// telemetry data once Phase 8 (GPS) and Phase 10 (routing engine) land.
// Kept as simple constants for now so the layout is easy to re-point later.
const _turnDistance = '700 m';
const _upcomingStreet = 'Jefferson Avenue';
const _currentSpeedKmh = 60;
const _tripSummary = '48 min  •  10:29  •  12 mi';
const _tripProgress = 0.42;

// Initial heading only, so the map opens already facing the right way
// instead of snapping into rotation after the first frame. After the first
// frame, _LiveRideScreenState's simulation timer takes over and
// recalculates this on every step.
//
// NOT negated (flutter_map's version of this was: `-bearingDegrees(...)`,
// with a comment about flutter_map's rotation running "opposite to compass
// bearing"). MapLibre's CameraPosition.bearing is defined as "the compass
// direction that is up" — exactly the plain heading-up formula, no flip
// needed. If the map ever looks rotated backwards again, this is the first
// place to check, but it shouldn't be.
final double _headingDeg = bearingDegrees(routePoints[0], routePoints[1]);

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
  // Unlike flutter_map's MapController (constructed directly),
  // MapLibreMapController is handed to us via onMapCreated once the native
  // map view is ready — so this starts null.
  MapLibreMapController? _mapController;

  // Live "you are here" state. Starts at the first route point and steps
  // forward along routePoints on a timer to fake movement. Once Phase 8
  // wires up real GPS, replace the timer with the position-stream listener
  // and feed each fix into this same state — the rotation logic underneath
  // doesn't need to change.
  LatLng _livePosition = routePoints.first;
  double _liveHeadingDeg = _headingDeg;
  int _routeIndex = 0;
  Timer? _simTimer;

  // True while the camera is heading-locked (the normal nav state).
  // Flipped off by _toggleNorthUp() and back on by _recenter(), same pattern
  // as Waze/Google Maps' compass button.
  bool _headingLocked = true;

  // Native MapLibre Symbol handles for the flag, heading puck, and rider
  // pins. These replace the old screen-pixel-projected Flutter-widget
  // overlay (ScreenMarker + toScreenLocationBatch): a Symbol is attached
  // directly to the map's own GPU layer, so it moves in lockstep with the
  // tiles on every pan/zoom/tilt frame — no async screen-position lookup,
  // no one-frame lag, no drift. Null until _registerMarkerSymbols() (called
  // from _onStyleLoaded) finishes adding them.
  Symbol? _flagSymbol;
  Symbol? _puckSymbol;
  List<Symbol?> _riderSymbols = const [null, null, null];

  // GlobalKeys on the (invisible, off-screen) RepaintBoundary-wrapped pin
  // widgets built in build() below. Each is rendered once, off-screen, so
  // its pixels can be captured via RenderRepaintBoundary.toImage() and
  // registered as a MapLibre style image — see _captureImage() and
  // _registerMarkerSymbols(). This is what lets the *same* MapPin /
  // RiderPin / _HeadingArrow widgets used elsewhere in the app become
  // native map icons instead of a parallel screen-position system.
  final _flagImageKey = GlobalKey();
  final _puckImageKey = GlobalKey();
  final _rider0ImageKey = GlobalKey();
  final _rider1ImageKey = GlobalKey();
  final _rider2ImageKey = GlobalKey();

  // Set once the hidden pin widgets have gone through a real layout/paint
  // pass, so _registerMarkerSymbols() (which needs their RenderObjects)
  // never runs before there's anything to capture.
  bool _hiddenMarkersReady = false;

  @override
  void initState() {
    super.initState();
    // Simulation timer disabled: this screen is for static UI prototyping
    // only, so the rider position/heading no longer advance on their own.
    // Re-enable this line (or swap it for the real position-stream
    // listener per the comments above) once movement is wanted again.
    // _simTimer = Timer.periodic(_simStepInterval, (_) => _advanceSimulatedPosition());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hiddenMarkersReady = true;
      // The map style can finish loading before or after this first frame,
      // so whichever of these two happens second is the one that actually
      // registers the symbols — see _onStyleLoaded and _maybeRegisterMarkerSymbols.
      _maybeRegisterMarkerSymbols();
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    _addRouteLine();
    // Native map-layer markers for the destination and the rider's current
    // position — unaffected by any of this, since they were already
    // lat/lng-anchored Circle annotations.
    _addLocationMarkers();
    // Flag/puck/rider-pin symbols also need the hidden pin widgets to have
    // been laid out and painted at least once (see initState's post-frame
    // callback) before they can be snapshotted into style images, so this
    // only actually registers them once both things are ready.
    _maybeRegisterMarkerSymbols();
  }

  // Runs _registerMarkerSymbols() exactly once, as soon as both of its
  // prerequisites are satisfied: the hidden pin widgets have been through a
  // real frame (_hiddenMarkersReady) and the map controller/style exists.
  // Style-load and first-frame timing aren't guaranteed to happen in any
  // particular order, so both call sites funnel through this guard instead
  // of assuming one always comes first.
  bool _markerSymbolsRegistered = false;
  void _maybeRegisterMarkerSymbols() {
    if (_markerSymbolsRegistered || !_hiddenMarkersReady || _mapController == null) return;
    _markerSymbolsRegistered = true;
    _registerMarkerSymbols();
  }

  // Registers each pin widget as a MapLibre style image, then adds one
  // native Symbol per marker at its real geo position. From here on,
  // moving a marker is just controller.updateSymbol(..., geometry: ...) —
  // no screen-pixel math, so no lag and no drift on zoom/pan/tilt.
  // Snapshotting each hidden pin widget is handled by the shared
  // captureWidgetImage() helper (../utils/widget_image_capture.dart), so
  // the paused/rest-stop screen's map can register its own pin images the
  // same way without duplicating this logic.
  Future<void> _registerMarkerSymbols() async {
    final controller = _mapController;
    if (controller == null) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    await controller.addImage(
        'pin_flag', await captureWidgetImage(_flagImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'pin_puck', await captureWidgetImage(_puckImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'pin_rider_jm', await captureWidgetImage(_rider0ImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'pin_rider_kr', await captureWidgetImage(_rider1ImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'pin_rider_mt', await captureWidgetImage(_rider2ImageKey, pixelRatio: pixelRatio));

    if (!mounted) return;

    final flagSymbol = await controller.addSymbol(SymbolOptions(
      geometry: routePoints.last,
      iconImage: 'pin_flag',
      iconAnchor: 'bottom',
    ));
    final puckSymbol = await controller.addSymbol(SymbolOptions(
      geometry: _livePosition,
      iconImage: 'pin_puck',
      // 'center', not 'bottom': the puck is now a symmetric arrow+glow
      // icon with no pointed tail, so the geo point should land in the
      // middle of the icon rather than at its base.
      iconAnchor: 'center',
    ));
    final riderSymbols = [
      await controller.addSymbol(SymbolOptions(
        geometry: groupPositions[0],
        iconImage: 'pin_rider_jm',
        iconAnchor: 'bottom',
      )),
      await controller.addSymbol(SymbolOptions(
        geometry: groupPositions[1],
        iconImage: 'pin_rider_kr',
        iconAnchor: 'bottom',
      )),
      await controller.addSymbol(SymbolOptions(
        geometry: groupPositions[2],
        iconImage: 'pin_rider_mt',
        iconAnchor: 'bottom',
      )),
    ];

    if (!mounted) return;
    setState(() {
      _flagSymbol = flagSymbol;
      _puckSymbol = puckSymbol;
      _riderSymbols = riderSymbols;
    });
  }

  // Route-ahead line: two overlapping native Line annotations fake the
  // casing/outline look flutter_map's PolylineLayer gave us for free — a
  // wide dark-purple line underneath, a narrower brighter one on top. Swap
  // routePoints for the real ORS polyline once Phase 10 lands.
  Future<void> _addRouteLine() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.addLine(LineOptions(
      geometry: routePoints,
      lineColor: colorToHex(routeShadowColor),
      lineWidth: 12,
      lineJoin: 'round',
    ));
    await controller.addLine(LineOptions(
      geometry: routePoints,
      lineColor: colorToHex(routeLineColor),
      lineWidth: 7,
      lineJoin: 'round',
    ));
  }

  // Guaranteed-visible marker for the destination, drawn as a native
  // MapLibre Circle annotation tied directly to lat/lng. This renders
  // immediately on style load, before the pin/arrow Symbol icons finish
  // their one-time image capture and registration (see
  // _registerMarkerSymbols) — so the route's end point is always marked
  // even during that brief setup window.
  //
  // There's no equivalent circle for the rider's own position anymore —
  // that's now carried entirely by the heading arrow itself (see
  // _HeadingArrow), rather than a separate green halo+dot underneath it.
  Future<void> _addLocationMarkers() async {
    final controller = _mapController;
    if (controller == null) return;

    Future<void> addMarker(LatLng at, Color color) async {
      await controller.addCircle(CircleOptions(
        geometry: at,
        circleRadius: 16,
        circleColor: colorToHex(color),
        circleOpacity: 0.25,
      ));
      await controller.addCircle(CircleOptions(
        geometry: at,
        circleRadius: 7,
        circleColor: colorToHex(color),
        circleStrokeColor: colorToHex(Colors.white),
        circleStrokeWidth: 2,
      ));
    }

    await addMarker(routePoints.last, turnSignColor); // destination
  }

  // Steps the rider one point further along the dummy route, recomputes the
  // bearing to the *next* point, and — if heading-lock is on — rotates the
  // map to match. This is what keeps the map "always pointing the
  // direction the rider should go" instead of rotating once at load and
  // freezing.
  //
  // Currently unused: the timer that called this on a loop was disabled in
  // initState() for static UI prototyping. Left in place (rather than
  // deleted) since it's also the template for the real GPS/heading stream
  // handler once Phase 8 lands.
  // ignore: unused_element
  void _advanceSimulatedPosition() {
    if (_routeIndex >= routePoints.length - 1) {
      // Loop back to the start so the demo keeps running. A real position
      // stream simply wouldn't fire once the ride ends.
      _routeIndex = 0;
    }
    final from = routePoints[_routeIndex];
    final to = routePoints[_routeIndex + 1];
    final newHeading = bearingDegrees(from, to); // not negated — see _headingDeg's comment

    setState(() {
      _livePosition = from;
      _liveHeadingDeg = newHeading;
      _routeIndex++;
    });

    // Move the native puck symbol to the new lat/lng directly — no
    // screen-pixel projection involved, so this stays glued to the map
    // through the camera animation below rather than lagging a frame
    // behind it.
    final puckSymbol = _puckSymbol;
    if (puckSymbol != null) {
      _mapController?.updateSymbol(puckSymbol, SymbolOptions(geometry: _livePosition));
    }

    if (_headingLocked) {
      final zoom = _mapController?.cameraPosition?.zoom ?? 15.5;
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: _livePosition, zoom: zoom, bearing: _liveHeadingDeg, tilt: _cameraTilt),
      ));
    }
  }

  // Recentres on "my" position and heading, and re-engages heading-lock if
  // the rider had panned away or hit "north up".
  void _recenter() {
    _headingLocked = true;
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: _livePosition, zoom: 15.5, bearing: _liveHeadingDeg, tilt: _cameraTilt),
    ));
  }

  // Nav apps that lock rotation to heading still give you a way back to
  // north-up — this toggles between the two instead of always forcing
  // north-up. Previously every tap set bearing to 0 unconditionally, so a
  // second tap looked like it did nothing; now it flips _headingLocked and
  // swaps the bearing to match, leaving target/zoom/tilt untouched either
  // way (_recenter(), the big cyan button, is still what re-centers
  // position).
  void _toggleNorthUp() {
    final current = _mapController?.cameraPosition;
    setState(() => _headingLocked = !_headingLocked);
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: current?.target ?? _livePosition,
        zoom: current?.zoom ?? 15.5,
        bearing: _headingLocked ? _liveHeadingDeg : 0,
        tilt: current?.tilt ?? _cameraTilt,
      ),
    ));
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
          // MAP LAYER — native MapLibre camera bearing + tilt give the
          // Waze-style forward tilt directly, no Matrix4/perspective hack
          // needed. Only the map layer tilts; every overlay below (header,
          // pills, panels, buttons) stays flat on screen since those are
          // ordinary Flutter widgets, not part of the tilted camera.
          // ---------------------------------------------------------------
          Positioned.fill(
            child: MapLibreMap(
              styleString: mapStyleUrl,
              initialCameraPosition: CameraPosition(
                target: LatLng(14.2620, 120.8770),
                zoom: 15.5,
                bearing: _headingDeg,
                tilt: _cameraTilt,
              ),
              trackCameraPosition: true,
              // Heading-up, like Waze: the map faces your direction of
              // travel instead of true north. Manual rotate/tilt gestures
              // are disabled since both are heading-locked and fixed —
              // _toggleNorthUp() is the way back to north-up. Our own
              // explore-icon button covers that, so the native compass
              // widget is turned off to avoid a redundant control.
              compassEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              // Explicit (rather than relying on the plugin's default) so
              // it's clear pinch-to-zoom is intentionally left on.
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              // No onCameraMove/onCameraIdle marker refresh needed anymore:
              // the flag/puck/rider pins are native Symbol annotations
              // (see _registerMarkerSymbols), so MapLibre repositions them
              // on its own GPU layer every frame the camera moves — the
              // same way the destination/position Circle annotations
              // below always tracked correctly.
            ),
          ),
          // Themed scrim over the raw basemap tiles — a top-and-bottom
          // asphalt gradient plus a soft edge vignette. This is what ties
          // the map's *visual display* to the rest of the app's dark
          // theme without touching MapLibre's tile rendering itself, and
          // it does double duty: it's exactly the darkening the header
          // and bottom stack need to stay legible over bright tiles.
          // IgnorePointer so gestures still reach the map underneath.
          const Positioned.fill(child: IgnorePointer(child: MapScrim())),
          // The flag, heading puck, and rider pins themselves are now
          // native MapLibre Symbol annotations, added by
          // _registerMarkerSymbols() straight onto the map's own GPU
          // layer — that's what fixes both the floating lag and the
          // zoom-time drift, since they're no longer reprojected into
          // screen pixels on every frame.
          //
          // The five widgets below are NOT visible markers: each one is
          // rendered once, off-screen (Positioned far outside the
          // viewport), purely so _captureMarkerImage() can snapshot its
          // pixels via RenderRepaintBoundary.toImage() and register that
          // PNG as a style image for the Symbol to use as its icon. This
          // is what lets the existing MapPin/RiderPin/_HeadingArrow
          // widgets double as native map icons without hand-drawing a
          // second, separate icon asset. IgnorePointer keeps them from
          // ever intercepting touches even though they're technically
          // still in the tree.
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  left: -1000,
                  top: -1000,
                  child: RepaintBoundary(
                    key: _flagImageKey,
                    child: const MapPin(
                      color: turnSignColor,
                      headDiameter: 30,
                      child: Icon(Icons.flag_rounded, color: Colors.white, size: 15),
                    ),
                  ),
                ),
                Positioned(
                  left: -1000,
                  top: -1000,
                  child: RepaintBoundary(
                    key: _puckImageKey,
                    child: const _HeadingArrow(),
                  ),
                ),
                Positioned(
                  left: -1000,
                  top: -1000,
                  child: RepaintBoundary(
                    key: _rider0ImageKey,
                    child: const RiderPin(initials: 'JM', color: AppColors.route),
                  ),
                ),
                Positioned(
                  left: -1000,
                  top: -1000,
                  child: RepaintBoundary(
                    key: _rider1ImageKey,
                    child: const RiderPin(initials: 'KR', color: AppColors.pine),
                  ),
                ),
                Positioned(
                  left: -1000,
                  top: -1000,
                  child: RepaintBoundary(
                    key: _rider2ImageKey,
                    child: const RiderPin(initials: 'MT', color: AppColors.rust),
                  ),
                ),
              ],
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
          // bottom, clear of the trip panel.
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
                  background: _musicColor,
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
                  // Filled when north-up override is active, so the
                  // button's own state now gives visible feedback that
                  // the second tap actually did something.
                  icon: _headingLocked ? Icons.explore_outlined : Icons.explore,
                  background: _headingLocked ? AppColors.asphalt2 : AppColors.route,
                  iconColor: _headingLocked ? AppColors.ink : AppColors.darkInk,
                  size: 42,
                  iconSize: 19,
                  onTap: _toggleNorthUp,
                ),
                const SizedBox(height: 12),
                _CircleButton(
                  icon: Icons.navigation_rounded,
                  background: liveMarkerColor,
                  iconColor: AppColors.darkInk,
                  size: 60,
                  iconSize: 26,
                  onTap: _recenter,
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // BOTTOM STACK — trip summary panel, then the existing
          // ride-control actions underneath. The current-street pill
          // ("John St.") that used to sit here has been removed.
          // ---------------------------------------------------------------
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  const _SpeedAndTripRow(),
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
// MapScrim now lives in ../widgets/map_scrim.dart, shared with the
// paused/rest-stop screen's map.
// -----------------------------------------------------------------------
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
        color: _headerColor,
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
              // Turn icon now sits on its own rust road-sign tile instead
              // of floating bare on the header — reads like an actual
              // highway sign chip rather than a plain icon+text row. Swap
              // the icon for the routing engine's real maneuver type
              // (left/right/roundabout/merge/...) once Phase 10 lands.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: turnSignColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: turnSignColor.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Anton (AppText.display) gives the distance the same
                    // bold "road sign" energy the type system was designed
                    // for, in place of the previous bespoke bold body text.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        distance.toUpperCase(),
                        style: AppText.display(size: 38, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppText.body(size: 17, weight: FontWeight.w700, color: AppColors.route),
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
// Speedometer (bottom-left) + trip summary panel (rest of width)
// -----------------------------------------------------------------------

class _SpeedAndTripRow extends StatelessWidget {
  const _SpeedAndTripRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _Speedometer(speedKmh: _currentSpeedKmh),
        const SizedBox(width: 12),
        const Expanded(child: _TripPanel()),
      ],
    );
  }
}

// Top-of-scale reference for the gauge's progress arc. Purely a display
// scale (not a hard cap) — swap for a per-vehicle value once that's
// available.
const _speedoMaxKmh = 140;

/// Redesigned speedometer: a real gauge instead of a flat metallic-ring
/// badge. A 270° arc drawn with CustomPaint sweeps from the bottom-left
/// round to the bottom-right, dial face and track in the app's asphalt
/// tones, progress arc in route gold, digits in Anton (AppText.display)
/// for the same road-sign weight as the turn-distance header.
class _Speedometer extends StatelessWidget {
  final int speedKmh;
  const _Speedometer({required this.speedKmh});

  @override
  Widget build(BuildContext context) {
    final progress = (speedKmh / _speedoMaxKmh).clamp(0.0, 1.0);
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _speedoDial,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: CustomPaint(
        painter: _SpeedGaugePainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$speedKmh',
                  style: AppText.display(size: 30, color: Colors.white),
                ),
              ),
              Text('km/h',
                  style: AppText.mono(size: 9, weight: FontWeight.w600, color: AppColors.inkDim)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the gauge's background track and the gold progress arc behind the
/// speed readout. Sweeps 270° (7:30 round to 4:30, clock-face-wise) so
/// there's always a visible gap at the bottom marking "empty".
class _SpeedGaugePainter extends CustomPainter {
  final double progress; // 0.0–1.0

  _SpeedGaugePainter({required this.progress});

  static const _startAngle = 0.75 * math.pi; // 135°
  static const _sweepAngle = 1.5 * math.pi; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = _speedoTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = _speedoArc
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, _startAngle, _sweepAngle * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) => oldDelegate.progress != progress;
}

class _TripPanel extends StatelessWidget {
  const _TripPanel();

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
                    valueColor: const AlwaysStoppedAnimation(routeLineColor),
                  ),
                ),
                // The hazard warning row ("Speed bumps in 500 m") that used
                // to sit here has been removed — it's not part of this
                // project. The white card is kept as a home for the trip
                // progress bar above.
                const SizedBox(height: 4),
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
// lightly restyled to sit under the new white trip panel.
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
// MapPin / RiderPin now live in ../widgets/map_pin.dart, shared with the
// paused/rest-stop screen's map so both use the exact same pin family
// instead of two copies drifting apart over time.
// -----------------------------------------------------------------------

/// The rider's own live-position marker — "you are here, facing this
/// way". No pin body anymore: just the direction arrow itself, colored to
/// match the app's "live GPS" green, sitting on a soft glow for the
/// pulsing-signal feel (Waze/Google Maps' live dot). The icon carries a
/// small drop shadow instead of the pin's old white stroke, so it stays
/// readable against both the light basemap tiles and the darker route
/// line/scrim.
class _HeadingArrow extends StatelessWidget {
  const _HeadingArrow();

  static const _iconSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _iconSize + 14,
          height: _iconSize + 14,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: liveMarkerColor.withOpacity(0.22)),
        ),
        Icon(
          Icons.navigation_rounded,
          color: liveMarkerColor,
          size: _iconSize,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))],
        ),
      ],
    );
  }
}
