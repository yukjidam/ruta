import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../data/ride_map_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/widget_image_capture.dart';
import '../widgets/app_button.dart';
import '../widgets/map_pin.dart';
import '../widgets/map_scrim.dart';

// ---------------------------------------------------------------------------
// Rest-stop redesign: while the ride is paused, the leader typically wants
// to actually *look at the map* — check the crew's spread, find a place to
// wait, eyeball how much road is left — rather than stare at a modal dialog
// blocking it. So instead of a dim overlay + centered card, this is a split
// screen: a real, pannable/zoomable map up top (not locked to heading like
// the live-ride nav view — this is a planning view), and a solid panel
// below it with the pause controls plus the two things worth checking at a
// glance: trip progress so far, and nearby points of interest.
//
// Reuses the same route/crew data, map style, pin family, and scrim as the
// live-ride screen (see ../data/ride_map_data.dart, ../widgets/map_pin.dart,
// ../widgets/map_scrim.dart) so both map screens read as one consistent
// map, not two different prototypes.
//
// The initial camera now also matches the live-ride screen's heading-up
// orientation (same _headingDeg bearing + _cameraTilt forward tilt) and
// gets the same destination circle-halo marker (_addLocationMarkers), so
// the map looks like the same map, just paused, rather than snapping to a
// flat north-up view. Pan/zoom/rotate/tilt gestures are still left on
// (unlike the live screen, which locks them) since this remains a
// planning view the leader can freely look around in.
// ---------------------------------------------------------------------------

// Camera pitch for the initial view, matching the live-ride screen's
// Waze-style forward tilt (see that screen's _cameraTilt comment).
const _cameraTilt = 50.0;

// Default opening zoom — a bit closer than the original 13.6 so the map
// doesn't open quite so zoomed-out.
const _defaultZoom = 14.5;

// Initial heading so the map opens facing the same direction as the
// live-ride screen instead of flat north-up. Unlike the live screen, this
// is never recalculated after load — there's no simulated/real position
// advancing while paused — and rotateGesturesEnabled is left on, so the
// leader can still freely spin the map to look around.
final double _headingDeg = bearingDegrees(routePoints[0], routePoints[1]);

// The puck (the user's own "you are here" arrow) shrinks as the leader
// zooms out, so it reads as a small position marker instead of a big
// distraction once they pinch out to see the whole route. Full size at
// _defaultZoom or tighter, shrinking linearly down to _puckMinScale by
// the time they reach _puckMinSizeZoom, and floored there for anything
// further out.
const _puckMinSizeZoom = 11.0;
const _puckMinScale = 0.55;

double _puckIconSizeForZoom(double zoom) {
  if (zoom >= _defaultZoom) return 1.0;
  if (zoom <= _puckMinSizeZoom) return _puckMinScale;
  final t = (zoom - _puckMinSizeZoom) / (_defaultZoom - _puckMinSizeZoom);
  return _puckMinScale + (1.0 - _puckMinScale) * t;
}

// Dummy trip-progress numbers — swap for real telemetry (distance covered
// via GPS trace, distance remaining via the routing engine) once Phase 8
// (GPS) and Phase 10 (routing) land. Kept as simple constants so this
// screen is easy to re-point at real data later, same pattern as the
// live-ride screen's dummy trip copy.
const _distanceCoveredKm = 18.4;
const _distanceRemainingKm = 11.2;
const _elapsedTrip = '48 min';
const _avgSpeedKmh = 42;

// Dummy "how long has the crew been resting" timer. Swap for a real
// Timer.periodic counting up from when the pause was triggered, once this
// screen is wired to actual pause/resume state instead of always opening
// fresh.
const _restDuration = '08:42';

/// One nearby point of interest the leader might route the rest stop
/// toward, or just want visibility into while planning. Swap `location`
/// and this dummy list for a real POI/places query against the map's
/// viewport once that's wired up — see the "location-dependent stats"
/// discussion this screen is based on.
class _NearbyStop {
  final String name;
  final String distance;
  final IconData icon;
  final Color color;
  final LatLng location;

  const _NearbyStop({
    required this.name,
    required this.distance,
    required this.icon,
    required this.color,
    required this.location,
  });
}

const _nearbyStops = [
  _NearbyStop(
    name: 'Shell Aguinaldo Hwy',
    distance: '650 m',
    icon: Icons.local_gas_station_rounded,
    color: AppColors.rust,
    location: LatLng(14.2612, 120.8802),
  ),
  _NearbyStop(
    name: "Ka Renz's Carinderia",
    distance: '1.1 km',
    icon: Icons.restaurant_rounded,
    color: AppColors.route,
    location: LatLng(14.2568, 120.8818),
  ),
  _NearbyStop(
    name: 'Petron Rest Area',
    distance: '2.4 km',
    icon: Icons.local_parking_rounded,
    color: AppColors.pine,
    location: LatLng(14.2542, 120.8758),
  ),
];

class PausedRideScreen extends StatefulWidget {
  const PausedRideScreen({super.key});

  @override
  State<PausedRideScreen> createState() => _PausedRideScreenState();
}

class _PausedRideScreenState extends State<PausedRideScreen> {
  MapLibreMapController? _mapController;

  // Native MapLibre Symbol handles for the destination flag, the crew
  // pins, and the nearby-stop markers — same lat/lng-anchored Symbol
  // approach as the live-ride screen (see that file's comments on why:
  // screen-pixel-projected overlays lag and drift on zoom, Symbols don't),
  // which matters even more here since this screen's whole point is
  // letting the leader freely pan/zoom to plan.
  Symbol? _flagSymbol;
  // The user's own "you are here" pin — same heading-arrow puck as the
  // live-ride screen, frozen at its paused position instead of advancing
  // (see _pausedPosition below). Like the live screen, the icon itself
  // doesn't rotate — it's the map's bearing that changes, not the arrow.
  Symbol? _puckSymbol;
  List<Symbol?> _riderSymbols = const [null, null, null];
  List<Symbol?> _stopSymbols = List<Symbol?>.filled(_nearbyStops.length, null);

  // Where the ride was paused — this screen has no live position stream
  // (or the live-ride screen's simulation timer), so there's no "current"
  // point to advance from. Standing in for real paused-state data once
  // Phase 8 (GPS) lands, this reuses the live-ride screen's own static
  // prototype value (routePoints.first, since its simulation timer is
  // currently disabled) so the two screens' puck sits in the same place.
  final LatLng _pausedPosition = routePoints.first;

  // GlobalKeys on the hidden, off-screen pin widgets built in build()
  // below — captured once into style images via captureWidgetImage(), the
  // same pipeline the live-ride screen uses.
  final _flagImageKey = GlobalKey();
  final _puckImageKey = GlobalKey();
  final _rider0ImageKey = GlobalKey();
  final _rider1ImageKey = GlobalKey();
  final _rider2ImageKey = GlobalKey();
  final List<GlobalKey> _stopImageKeys = List.generate(_nearbyStops.length, (_) => GlobalKey());

  bool _hiddenMarkersReady = false;
  bool _markerSymbolsRegistered = false;

  // Zoom bucket (nearest 0.5) the puck's icon size was last set for, so
  // _onCameraChanged only calls updateSymbol() when the zoom has actually
  // moved to a new bucket — not on every intermediate frame of a pinch
  // gesture.
  double? _lastPuckZoomBucket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hiddenMarkersReady = true;
      _maybeRegisterMarkerSymbols();
    });
  }

  @override
  void dispose() {
    _mapController?.removeListener(_onCameraChanged);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    // trackCameraPosition (set on the MapLibreMap widget below) is what
    // makes the controller notify listeners as the camera moves, which
    // is what drives the puck's zoom-based resizing in _onCameraChanged.
    controller.addListener(_onCameraChanged);
  }

  // Shrinks/grows the puck icon to match the current zoom (see
  // _puckIconSizeForZoom). Only the puck resizes — the flag/rider/stop
  // pins keep their fixed on-screen size, same as the live-ride screen.
  void _onCameraChanged() {
    final zoom = _mapController?.cameraPosition?.zoom;
    final puckSymbol = _puckSymbol;
    if (zoom == null || puckSymbol == null) return;
    final bucket = (zoom * 2).round() / 2; // nearest 0.5
    if (bucket == _lastPuckZoomBucket) return;
    _lastPuckZoomBucket = bucket;
    _mapController?.updateSymbol(
      puckSymbol,
      SymbolOptions(iconSize: _puckIconSizeForZoom(zoom)),
    );
  }

  void _onStyleLoaded() {
    _addRouteLine();
    // Same destination circle-halo marker as the live-ride screen (see
    // that screen's _addLocationMarkers) — renders immediately on style
    // load, before the pin Symbol icons finish their one-time image
    // capture/registration, so the destination is always marked.
    _addLocationMarkers();
    // Applies to every Symbol annotation (not per-symbol — MapLibre's
    // icon-allow-overlap/icon-ignore-placement are layout properties on
    // the whole layer, not SymbolOptions fields, so there's no per-pin
    // equivalent). The puck is the one marker that must never be hidden
    // by collision with the flag/rider/stop pins, and since this screen
    // has few enough markers overall, letting them all skip collision
    // checks doesn't create real clutter.
    _mapController?.setSymbolIconAllowOverlap(true);
    _mapController?.setSymbolIconIgnorePlacement(true);
    _maybeRegisterMarkerSymbols();
  }

  // Same "run exactly once, whichever prerequisite finishes last" guard as
  // the live-ride screen — style load and the hidden widgets' first paint
  // aren't guaranteed to happen in any particular order.
  void _maybeRegisterMarkerSymbols() {
    if (_markerSymbolsRegistered || !_hiddenMarkersReady || _mapController == null) return;
    _markerSymbolsRegistered = true;
    _registerMarkerSymbols();
  }

  // Same two-layer casing trick as the live-ride screen's route line, so
  // the road the crew has already ridden (and what's ahead) reads
  // identically on both screens.
  Future<void> _addRouteLine() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.addLine(LineOptions(
      geometry: routePoints,
      lineColor: colorToHex(routeShadowColor),
      lineWidth: 10,
      lineJoin: 'round',
    ));
    await controller.addLine(LineOptions(
      geometry: routePoints,
      lineColor: colorToHex(routeLineColor),
      lineWidth: 6,
      lineJoin: 'round',
    ));
  }

  // Guaranteed-visible marker for the destination, drawn as a native
  // MapLibre Circle annotation tied directly to lat/lng — identical to
  // the live-ride screen's version, so the destination reads the same way
  // on both maps.
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

  Future<void> _registerMarkerSymbols() async {
    final controller = _mapController;
    if (controller == null) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    await controller.addImage(
        'paused_pin_flag', await captureWidgetImage(_flagImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'paused_pin_puck', await captureWidgetImage(_puckImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'paused_pin_rider_jm', await captureWidgetImage(_rider0ImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'paused_pin_rider_kr', await captureWidgetImage(_rider1ImageKey, pixelRatio: pixelRatio));
    await controller.addImage(
        'paused_pin_rider_mt', await captureWidgetImage(_rider2ImageKey, pixelRatio: pixelRatio));
    for (var i = 0; i < _nearbyStops.length; i++) {
      await controller.addImage(
          'paused_stop_$i', await captureWidgetImage(_stopImageKeys[i], pixelRatio: pixelRatio));
    }

    if (!mounted) return;

    final flagSymbol = await controller.addSymbol(SymbolOptions(
      geometry: routePoints.last,
      iconImage: 'paused_pin_flag',
      iconAnchor: 'bottom',
    ));
    final puckSymbol = await controller.addSymbol(SymbolOptions(
      geometry: _pausedPosition,
      iconImage: 'paused_pin_puck',
      // 'center', not 'bottom' — same symmetric arrow+glow icon as the
      // live-ride screen, so the geo point lands in the icon's middle.
      iconAnchor: 'center',
      iconSize: _puckIconSizeForZoom(_defaultZoom),
    ));
    final riderSymbols = [
      await controller.addSymbol(SymbolOptions(
        geometry: groupPositions[0],
        iconImage: 'paused_pin_rider_jm',
        iconAnchor: 'bottom',
      )),
      await controller.addSymbol(SymbolOptions(
        geometry: groupPositions[1],
        iconImage: 'paused_pin_rider_kr',
        iconAnchor: 'bottom',
      )),
      await controller.addSymbol(SymbolOptions(
        geometry: groupPositions[2],
        iconImage: 'paused_pin_rider_mt',
        iconAnchor: 'bottom',
      )),
    ];
    final stopSymbols = <Symbol?>[];
    for (var i = 0; i < _nearbyStops.length; i++) {
      stopSymbols.add(await controller.addSymbol(SymbolOptions(
        geometry: _nearbyStops[i].location,
        iconImage: 'paused_stop_$i',
        iconAnchor: 'bottom',
      )));
    }

    if (!mounted) return;
    setState(() {
      _flagSymbol = flagSymbol;
      _puckSymbol = puckSymbol;
      _riderSymbols = riderSymbols;
      _stopSymbols = stopSymbols;
    });
  }

  // Tapping a nearby-stop card pans/zooms the map to it — the point of
  // showing these while paused is letting the leader actually plan toward
  // one, not just glance at a list.
  void _focusOnStop(LatLng location) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15.8));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: Column(
        children: [
          // -----------------------------------------------------------
          // MAP — a planning view, not the live-ride nav view: rotate/
          // tilt/zoom/pan are all still left on so the leader can freely
          // look around while the crew rests, and there's no ongoing
          // heading-lock recalculation. But it now *opens* on the same
          // heading-up bearing + forward tilt as the live-ride screen
          // (_headingDeg/_cameraTilt above), centered roughly over the
          // group, so the map doesn't jar into a flat north-up view the
          // moment the ride is paused.
          // -----------------------------------------------------------
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MapLibreMap(
                  styleString: mapStyleUrl,
                  initialCameraPosition: CameraPosition(
                    target: const LatLng(14.2600, 120.8780),
                    zoom: _defaultZoom,
                    bearing: _headingDeg,
                    tilt: _cameraTilt,
                  ),
                  // Needed so the controller notifies listeners as the
                  // camera moves — see _onCameraChanged, which uses that
                  // to shrink/grow the puck icon with zoom.
                  trackCameraPosition: true,
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                ),
                // Lighter than the live-ride screen's scrim: this map
                // only needs contrast for the small stats pill up top,
                // and hands off to a solid panel (not more map) at the
                // bottom, so it doesn't need the heavier bottom darkening
                // that screen's full-bleed chrome needs.
                const Positioned.fill(
                  child: IgnorePointer(child: MapScrim(topOpacity: 0.45, bottomOpacity: 0.15)),
                ),
                // Hidden, off-screen pin widgets used only to snapshot
                // each into a style image once — see _registerMarkerSymbols
                // and ../utils/widget_image_capture.dart. Never visible;
                // the actual on-map markers are the native Symbols above.
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
                      for (var i = 0; i < _nearbyStops.length; i++)
                        Positioned(
                          left: -1000,
                          top: -1000 - (i + 1) * 80.0, // stacked so none overlap off-screen
                          child: RepaintBoundary(
                            key: _stopImageKeys[i],
                            child: MapPin(
                              color: _nearbyStops[i].color,
                              headDiameter: 28,
                              child: Icon(_nearbyStops[i].icon, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Trip-progress stats overlay — the "what's happened on
                // this ride so far" glance the leader wants while
                // deciding how long to actually rest.
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: SafeArea(bottom: false, child: _TripProgressBar()),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------
          // BOTTOM PANEL — pause status + rest timer, nearby stops to
          // plan toward, then the resume/end controls. A solid panel
          // (not another map layer or dim overlay) so it reads clearly
          // as "you're safely paused" chrome, distinct from the map
          // above it.
          // -----------------------------------------------------------
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.asphalt2,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration:
                                const BoxDecoration(color: AppColors.route, shape: BoxShape.circle),
                            child: const Icon(Icons.pause, color: AppColors.darkInk, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ride paused', style: AppText.display(size: 20)),
                                const SizedBox(height: 2),
                                Text(
                                  "Juan called a rest stop. Everyone's position is holding.",
                                  style: AppText.body(size: 12, color: AppColors.inkDim)
                                      .copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_restDuration,
                                  style: AppText.mono(
                                      size: 22, color: AppColors.route, weight: FontWeight.w700)),
                              Text('resting',
                                  style: AppText.mono(
                                      size: 9, weight: FontWeight.w600, color: AppColors.inkDim)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Nearby',
                          style: AppText.body(
                              size: 12, weight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _nearbyStops.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final stop = _nearbyStops[index];
                            return _NearbyStopCard(
                                stop: stop, onTap: () => _focusOnStop(stop.location));
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppButton(label: 'Resume ride', onPressed: () => Navigator.pop(context)),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'End ride here instead',
                        variant: AppButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Trip-progress overlay — a translucent pill of four stats sitting over
// the map, echoing the trip-summary pill style from the live-ride screen
// so both screens' "here's the trip at a glance" chrome reads as the same
// component family.
// -----------------------------------------------------------------------

class _TripProgressBar extends StatelessWidget {
  const _TripProgressBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TripStat(
            icon: Icons.route_rounded,
            value: '${_distanceCoveredKm.toStringAsFixed(1)} km',
            label: 'covered',
          ),
          _statDivider(),
          _TripStat(
            icon: Icons.flag_rounded,
            value: '${_distanceRemainingKm.toStringAsFixed(1)} km',
            label: 'to go',
          ),
          _statDivider(),
          const _TripStat(icon: Icons.schedule_rounded, value: _elapsedTrip, label: 'elapsed'),
          _statDivider(),
          const _TripStat(icon: Icons.speed_rounded, value: '$_avgSpeedKmh km/h', label: 'avg'),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white24,
      );
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _TripStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.route, size: 16),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: AppText.mono(size: 13, weight: FontWeight.w700, color: Colors.white)),
          ),
          Text(label, style: AppText.mono(size: 8, weight: FontWeight.w600, color: Colors.white70)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Nearby-stop card — a small tappable card in the horizontal "Nearby"
// list. Tapping pans the map above to that stop (see _focusOnStop), so
// this list and the map work as one connected planning tool rather than
// two separate displays of the same data.
// -----------------------------------------------------------------------

class _NearbyStopCard extends StatelessWidget {
  final _NearbyStop stop;
  final VoidCallback onTap;

  const _NearbyStopCard({required this.stop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.asphalt3,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: stop.color, shape: BoxShape.circle),
              child: Icon(stop.icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stop.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 11.5, weight: FontWeight.w700, color: Colors.white)
                        .copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(stop.distance,
                      style:
                          AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.inkDim)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// The user's own "you are here" pin — direction arrow on a soft glow,
// identical to the live-ride screen's _HeadingArrow. That version is a
// library-private class in live_ride_screen.dart so it can't be imported
// here directly; this is a duplicate rather than a shared import.
// TODO: move this into ../widgets/map_pin.dart alongside MapPin/RiderPin
// (which already made that jump) and have both screens import it from
// there, so the two copies can't drift apart the way this one now can.
// -----------------------------------------------------------------------
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
