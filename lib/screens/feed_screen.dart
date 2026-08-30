import 'package:flutter/material.dart';

import '../main.dart';
import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/ride_post_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = dummyProfiles.firstWhere((p) => p.id == 'me');

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Logbook', style: AppText.display(size: 24, color: AppColors.darkInk)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
                        icon: const Icon(Icons.search, color: AppColors.darkInk),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.profile, arguments: me),
                        child: const AppAvatar(
                            initials: 'JM', color: AppColors.route, textColor: AppColors.darkInk),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                itemCount: dummyRides.length,
                itemBuilder: (context, i) => RidePostCard(
                  ride: dummyRides[i],
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.rideDetail,
                    arguments: dummyRides[i],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.rust,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.planRide),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
