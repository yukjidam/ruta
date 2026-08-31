import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/screen_marker.dart';

// Free, open vector basemap — no API key, no account, no usage cap. Same
// style as live_ride_screen.dart so the two screens' maps look consistent.
// See openfreemap.org if a different look (liberty/bright/dark/fiord) or
// self-hosting is ever wanted.
const _mapStyleUrl = 'https://tiles.openfreemap.org/styles/positron';

/// Which field the next map tap should set.
enum _PinMode { destination, meetup }

/// A single geocoding result from Nominatim.
class _PlaceSuggestion {
  final String displayName;
  final LatLng point;
  const _PlaceSuggestion({required this.displayName, required this.point});
}

class PlanRideScreen extends StatefulWidget {
  const PlanRideScreen({super.key});

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
  // Unlike flutter_map's MapController (constructed directly),
  // MapLibreMapController is handed to us via onMapCreated once the native
  // map view is ready — so this starts null.
  MapLibreMapController? _mapController;

  final TextEditingController _destinationController =
      TextEditingController(text: 'Tagaytay Ridge, Cavite');
  final TextEditingController _meetupController =
      TextEditingController(text: 'Petron SLEX Sta. Rosa');

  // Seeded with the dummy destination/meet-up so the map opens centered
  // on something meaningful instead of null island. Swap for
  // ride.destinationLatLng / ride.meetupLatLng once real ride objects
  // exist (Phase 6).
  LatLng? _destination = const LatLng(14.1153, 120.9621); // Tagaytay Ridge
  LatLng? _meetup = const LatLng(14.2540, 121.1090); // Petron SLEX Sta. Rosa

  // The text that actually matches where each pin currently sits — set
  // whenever the pin moves (map tap or a chosen suggestion), so the
  // fields can warn if their text has since drifted from that.
  late String _destinationConfirmedText = _destinationController.text;
  late String _meetupConfirmedText = _meetupController.text;

  _PinMode _mode = _PinMode.destination;

  // Screen-pixel positions for the two pin marker widgets — see
  // widgets/screen_marker.dart for why these exist instead of a
  // flutter_map-style MarkerLayer. Null until the first lookup completes.
  math.Point<double>? _destinationScreenPoint;
  math.Point<double>? _meetupScreenPoint;

  @override
  void dispose() {
    _destinationController.dispose();
    _meetupController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    _refreshPinScreenPositions();
  }

  // Converts both pins' lat/lng into screen-pixel offsets for this frame's
  // camera position. Called after the style loads and on every
  // onCameraIdle (i.e. whenever a pan/zoom/recenter finishes).
  Future<void> _refreshPinScreenPositions() async {
    final controller = _mapController;
    if (controller == null) return;
    final destination = _destination;
    final meetup = _meetup;
    final rawPoints = await controller.toScreenLocationBatch([
      if (destination != null) destination,
      if (meetup != null) meetup,
    ]);
    // toScreenLocationBatch returns Point<num>, not Point<double> — convert
    // explicitly rather than declaring our fields as Point<num>, so every
    // other line touching .x/.y (in ScreenMarker) can keep assuming double.
    final points =
        rawPoints.map((p) => math.Point<double>(p.x.toDouble(), p.y.toDouble())).toList();
    if (!mounted) return;
    setState(() {
      var i = 0;
      _destinationScreenPoint = destination != null ? points[i++] : null;
      _meetupScreenPoint = meetup != null ? points[i++] : null;
    });
  }

  // Manual fallback: tapping the map fine-tunes whichever pin is active.
  // Since a raw tap has no place name, the field just shows coordinates
  // until the user searches again.
  //
  // A plain tap doesn't move the camera, so the tapped screen point is
  // already exactly where the pin should render — no need to wait for an
  // onCameraIdle round trip to place it.
  //
  // Parameter typed Point<num> (not Point<double>, like the fields above)
  // because this is a tear-off handed directly to onMapClick — its
  // parameter type has to match (or be a supertype of) whatever maplibre_gl
  // actually declares for that callback, and num is the safe common ground
  // regardless of whether that's double or num underneath.
  void _handleMapTap(math.Point<num> point, LatLng coordinates) {
    final screenPoint = math.Point<double>(point.x.toDouble(), point.y.toDouble());
    setState(() {
      if (_mode == _PinMode.destination) {
        _destination = coordinates;
        _destinationScreenPoint = screenPoint;
        _destinationController.text = _formatLatLng(coordinates);
        _destinationConfirmedText = _destinationController.text;
      } else {
        _meetup = coordinates;
        _meetupScreenPoint = screenPoint;
        _meetupController.text = _formatLatLng(coordinates);
        _meetupConfirmedText = _meetupController.text;
      }
    });
  }

  void _handleDestinationSelected(_PlaceSuggestion suggestion) {
    setState(() {
      _destination = suggestion.point;
      _mode = _PinMode.destination;
      _destinationConfirmedText = _destinationController.text;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(suggestion.point, 15));
  }

  void _handleMeetupSelected(_PlaceSuggestion suggestion) {
    setState(() {
      _meetup = suggestion.point;
      _mode = _PinMode.meetup;
      _meetupConfirmedText = _meetupController.text;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(suggestion.point, 15));
  }

  // Tapping into either field jumps the map to whatever that field is
  // currently set to, and makes it the active pin for map taps/results.
  void _handleDestinationFieldActivated() {
    setState(() => _mode = _PinMode.destination);
    final destination = _destination;
    if (destination != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(destination, 15));
    }
  }

  void _handleMeetupFieldActivated() {
    setState(() => _mode = _PinMode.meetup);
    final meetup = _meetup;
    if (meetup != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(meetup, 15));
    }
  }

  String _formatLatLng(LatLng? point) {
    if (point == null) return 'Tap the map to set';
    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.inkDim),
                ),
                Text('Plan a ride', style: AppText.display(size: 18)),
              ],
            ),
            // Live map view. Tap the map to drop a pin for whichever field
            // is active — toggled by the chips below.
            Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.asphalt3),
              ),
              child: Stack(
                children: [
                  MapLibreMap(
                    styleString: _mapStyleUrl,
                    initialCameraPosition: CameraPosition(
                      target: _destination ?? const LatLng(14.15, 121.0),
                      zoom: 14,
                    ),
                    trackCameraPosition: true,
                    onMapCreated: _onMapCreated,
                    onStyleLoadedCallback: _onStyleLoaded,
                    onMapClick: _handleMapTap,
                    // onCameraIdle alone only refreshes once a drag/pinch
                    // gesture finishes, so the pins would sit frozen
                    // mid-drag and snap into place afterwards —
                    // onCameraMove fires continuously while the camera is
                    // moving, keeping them glued to the map during the
                    // gesture itself.
                    onCameraMove: (_) => _refreshPinScreenPositions(),
                    onCameraIdle: _refreshPinScreenPositions,
                  ),
                  if (_destination != null)
                    ScreenMarker(
                      point: _destinationScreenPoint,
                      width: 28,
                      height: 28,
                      anchor: Alignment.bottomCenter,
                      child: const Icon(Icons.location_pin, color: AppColors.route, size: 28),
                    ),
                  if (_meetup != null)
                    ScreenMarker(
                      point: _meetupScreenPoint,
                      width: 24,
                      height: 24,
                      anchor: Alignment.bottomCenter,
                      child: const Icon(Icons.location_pin, color: AppColors.rust, size: 24),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _PinModeChip(
                      label: 'Destination',
                      color: AppColors.route,
                      selected: _mode == _PinMode.destination,
                      onTap: () => setState(() => _mode = _PinMode.destination),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PinModeChip(
                      label: 'Meet-up point',
                      color: AppColors.rust,
                      selected: _mode == _PinMode.meetup,
                      onTap: () => setState(() => _mode = _PinMode.meetup),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocationSearchField(
                      label: 'Destination',
                      hint: 'Search a place e.g. Market! Market! BGC',
                      accent: AppColors.route,
                      controller: _destinationController,
                      confirmedText: _destinationConfirmedText,
                      onSelected: _handleDestinationSelected,
                      onActivated: _handleDestinationFieldActivated,
                    ),
                    const SizedBox(height: 12),
                    _LocationSearchField(
                      label: 'Meet-up point',
                      hint: 'Search a place to meet the crew',
                      accent: AppColors.rust,
                      controller: _meetupController,
                      confirmedText: _meetupConfirmedText,
                      onSelected: _handleMeetupSelected,
                      onActivated: _handleMeetupFieldActivated,
                    ),
                    const SizedBox(height: 18),
                    Text('Invite crew',
                        style: AppText.mono(size: 10, color: AppColors.inkDim, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const AppAvatar(initials: 'KR', color: AppColors.pine, size: 32),
                        const SizedBox(width: 8),
                        const AppAvatar(initials: 'MT', color: AppColors.rust, size: 32),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.inkDim, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, size: 16, color: AppColors.inkDim),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.route.withOpacity(0.08),
                        border: Border.all(color: AppColors.routeDim),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('★', style: TextStyle(color: AppColors.route)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppText.body(size: 11.5, color: AppColors.inkDim)
                                    .copyWith(height: 1.5),
                                children: const [
                                  TextSpan(
                                      text: "You're setting the destination, which makes you "),
                                  TextSpan(
                                    text: 'ride leader',
                                    style: TextStyle(
                                        color: AppColors.ink, fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: ". You'll control the ride once it starts."),
                                ],
                              ),
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: AppColors.asphalt,
            border: Border(top: BorderSide(color: AppColors.asphalt3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: AppButton(
              label: 'Continue to lobby',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.lobby),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinModeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PinModeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          border: Border.all(color: selected ? color : AppColors.asphalt3),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_pin, size: 14, color: selected ? color : AppColors.inkDim),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppText.mono(
                  size: 10, color: selected ? AppColors.ink : AppColors.inkDim, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final Color accent;
  final TextEditingController controller;
  // The text that matches where the pin actually is right now. If the
  // controller's text has drifted from this, the pin is stale.
  final String confirmedText;
  final ValueChanged<_PlaceSuggestion> onSelected;
  final VoidCallback onActivated;

  const _LocationSearchField({
    required this.label,
    required this.hint,
    required this.accent,
    required this.controller,
    required this.confirmedText,
    required this.onSelected,
    required this.onActivated,
  });

  @override
  State<_LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<_LocationSearchField> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<_PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  // True once a search has actually run and come back empty, so we can
  // tell "haven't searched yet" apart from "searched, found nothing".
  bool _searchedWithNoResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) widget.onActivated();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _searchedWithNoResults = false);
    if (value.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(value));
  }

  // Nominatim — OpenStreetMap's free geocoding endpoint. No key required,
  // but it's a real network call now, so this is debounced above and
  // capped to 5 results. Swap `countrycodes` or drop it entirely once
  // this needs to search outside the Philippines.
  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'ph',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'com.ruta.app (ride planning search)'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _suggestions = data.map((item) {
            final map = item as Map<String, dynamic>;
            return _PlaceSuggestion(
              displayName: map['display_name'] as String,
              point: LatLng(
                double.parse(map['lat'] as String),
                double.parse(map['lon'] as String),
              ),
            );
          }).toList();
          _searchedWithNoResults = _suggestions.isEmpty;
        });
      }
    } catch (_) {
      // Offline, or the free endpoint is rate-limiting — fail quietly.
      // Worth a proper error state once this sits behind a real backend.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(_PlaceSuggestion suggestion) {
    widget.controller.text = suggestion.displayName;
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
    widget.onSelected(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final bool isStale =
        widget.controller.text.isNotEmpty && widget.controller.text != widget.confirmedText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.asphalt2,
            border: Border.all(color: AppColors.asphalt3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label.toUpperCase(),
                  style: AppText.mono(size: 10, color: widget.accent, letterSpacing: 1)),
              TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                style: AppText.body(size: 14, weight: FontWeight.w600),
                cursorColor: widget.accent,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: AppText.body(size: 13, color: AppColors.inkDim),
                  suffixIcon: _loading
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent),
                          ),
                        )
                      : const Icon(Icons.search, size: 18, color: AppColors.inkDim),
                ),
              ),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.asphalt2,
              border: Border.all(color: AppColors.asphalt3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: _suggestions.map((s) {
                return InkWell(
                  onTap: () => _select(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: widget.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.displayName,
                            style: AppText.body(size: 12.5, color: AppColors.inkDim),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else if (_searchedWithNoResults)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.asphalt2,
              border: Border.all(color: AppColors.asphalt3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_off, size: 16, color: AppColors.inkDim),
                const SizedBox(width: 8),
                Text('No places found', style: AppText.body(size: 12.5, color: AppColors.inkDim)),
              ],
            ),
          )
        else if (isStale)
          // Field text has drifted from the last confirmed suggestion —
          // the pin on the map hasn't moved to match it yet.
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: AppColors.rust),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pin is still at the last selected location — pick a result to move it.',
                    style: AppText.body(size: 11, color: AppColors.inkDim),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
