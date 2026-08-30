import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared bottom nav across Feed / Garage / Crew / Notifications — the
/// four "home base" screens a rider bounces between when not actively
/// on a ride.
///
/// This no longer navigates routes itself — it lives inside [HomeShell]
/// (see home_shell.dart) which keeps all four screens alive in an
/// IndexedStack and just swaps which one is visible. That's what makes
/// the bottom nav feel persistent instead of flashing on every tap.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  /// Called with the tapped tab's index. The shell updates its
  /// IndexedStack index in response — no Navigator involved.
  final ValueChanged<int> onTap;

  /// Shows a small dot on the notifications icon. Wire this to a real
  /// unread count once notifications move off dummy data.
  final bool hasUnreadNotifications;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
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
        children: List.generate(icons.length, (i) {
          final active = i == currentIndex;
          final color = active ? AppColors.route : AppColors.inkDim;
          final isNotifTab = i == 3;

          return InkWell(
            onTap: active ? null : () => onTap(i),
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
