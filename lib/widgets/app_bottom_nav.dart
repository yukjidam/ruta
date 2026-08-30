import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_colors.dart';

/// Shared bottom nav across Feed / Garage / Crew / Notifications — the
/// four "home base" screens a rider bounces between when not actively
/// on a ride.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  /// Shows a small dot on the notifications icon. Wire this to a real
  /// unread count once notifications move off dummy data.
  final bool hasUnreadNotifications;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    final routes = [AppRoutes.feed, AppRoutes.garage, AppRoutes.crew, AppRoutes.notifications];
    final icons = [
      Icons.menu_book_outlined,
      Icons.two_wheeler_outlined,
      Icons.groups_outlined,
      Icons.notifications_outlined,
    ];
    final labels = ['Logbook', 'Garage', 'Crew', 'Alerts'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.asphalt2,
        border: Border(top: BorderSide(color: AppColors.asphalt3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(routes.length, (i) {
          final active = i == currentIndex;
          final color = active ? AppColors.route : AppColors.inkDim;
          final isNotifTab = i == 3;

          return InkWell(
            onTap: active ? null : () => Navigator.pushReplacementNamed(context, routes[i]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icons[i], color: color, size: 22),
                    if (isNotifTab && hasUnreadNotifications && !active)
                      Positioned(
                        top: -2,
                        right: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.rust,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(labels[i], style: TextStyle(color: color, fontSize: 10)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
