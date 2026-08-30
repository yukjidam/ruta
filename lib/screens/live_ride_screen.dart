import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/stat_column.dart';

class LiveRideScreen extends StatelessWidget {
  const LiveRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: Stack(
        children: [
          // Live OpenStreetMap view. Dummy rider positions along
          // Aguinaldo Hwy for now — swap for Supabase Realtime broadcast
          // positions once Phase 7 wires up real GPS.
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(14.2620, 120.8770),
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ruta.app',
              ),
              MarkerLayer(
                markers: const [
                  Marker(
                    point: LatLng(14.2635, 120.8755),
                    width: 34,
                    height: 34,
                    child: _RiderPin(initials: 'JM', color: AppColors.route),
                  ),
                  Marker(
                    point: LatLng(14.2600, 120.8790),
                    width: 34,
                    height: 34,
                    child: _RiderPin(initials: 'KR', color: AppColors.pine),
                  ),
                  Marker(
                    point: LatLng(14.2580, 120.8810),
                    width: 34,
                    height: 34,
                    child: _RiderPin(initials: 'MT', color: AppColors.rust),
                  ),
                ],
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
                ],
              ),
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.asphalt2,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('↰', style: TextStyle(fontSize: 26, color: AppColors.route)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Turn left onto Aguinaldo Hwy',
                                style: AppText.body(size: 14.5, weight: FontWeight.w700)),
                            Text('800 m · then continue 6.2 km', style: AppText.mono(size: 10.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AppColors.asphalt.withOpacity(0.95), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StatColumn(value: '34', label: 'km/h'),
                          StatColumn(value: '18.4', label: 'km left'),
                          StatColumn(value: '0:26', label: 'eta'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.asphalt2,
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
                                shape:
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Rest stop',
                                  style: AppText.body(size: 13, weight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, AppRoutes.captureMemory),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.rust,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape:
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('End ride',
                                  style: AppText.body(
                                      size: 13, weight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        border: Border.all(color: AppColors.asphalt, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: AppText.mono(size: 10, weight: FontWeight.w700, color: AppColors.darkInk)),
    );
  }
}
