import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Standard OpenStreetMap tile layer + required attribution, shared by
/// every screen that embeds a FlutterMap (Plan a Ride, Live Ride, and
/// whatever comes next).
///
/// Usage — drop these into FlutterMap's `children`, with any MarkerLayer
/// (or other overlay) sandwiched between them so markers sit above the
/// tiles but below the attribution chip:
///
///   FlutterMap(
///     children: [
///       RutaMapLayers.tileLayer(),
///       MarkerLayer(markers: [...]),
///       RutaMapLayers.attribution(),
///     ],
///   )
///
/// NOTE: this hits tile.openstreetmap.org directly, which is fine for
/// dev/demo traffic but has real usage limits. Before real-world release
/// (Phase 13), swap `urlTemplate` for a paid tile provider or put a
/// caching layer in front of it — see the README's Phase 6 notes.
class RutaMapLayers {
  RutaMapLayers._();

  static TileLayer tileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.ruta.app',
    );
  }

  static Widget attribution() {
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      attributions: [
        TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
      ],
    );
  }
}
