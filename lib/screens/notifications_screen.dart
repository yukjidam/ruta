import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/section_eyebrow.dart';

enum _NotifType { invite, heart, comment }

class _NotifItem {
  final _NotifType type;
  final String initials;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _NotifItem({
    required this.type,
    required this.initials,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Dummy feed — invite is deliberately first regardless of time, since
  // ride invites always get pinned above hearts/comments.
  static final List<_NotifItem> _notifications = [
    const _NotifItem(
      type: _NotifType.invite,
      initials: 'JM',
      color: AppColors.route,
      title: 'Juan invited you to ride',
      subtitle: 'Tagaytay Ridge · leaving in 20 min',
      time: 'Just now',
    ),
    const _NotifItem(
      type: _NotifType.heart,
      initials: 'KR',
      color: AppColors.pine,
      title: 'Kim Reyes hearted your ride',
      subtitle: 'Batangas Coastal Loop',
      time: '2h',
    ),
    const _NotifItem(
      type: _NotifType.comment,
      initials: 'MT',
      color: AppColors.rust,
      title: 'Mar Tan commented on your ride',
      subtitle: '"Ganda ng view dito, sulit yung akyat!"',
      time: '5h',
    ),
    const _NotifItem(
      type: _NotifType.heart,
      initials: 'AL',
      color: AppColors.asphalt3,
      title: 'Al Santos hearted your ride',
      subtitle: 'Sunrise run to Mt. Samat',
      time: '1d',
    ),
    const _NotifItem(
      type: _NotifType.comment,
      initials: 'KR',
      color: AppColors.pine,
      title: 'Kim Reyes commented on your ride',
      subtitle: '"Same time next month?"',
      time: '2d',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final invites = _notifications.where((n) => n.type == _NotifType.invite).toList();
    final rest = _notifications.where((n) => n.type != _NotifType.invite).toList();

    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionEyebrow(text: 'Notifications'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  ...invites.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PulsingGlow(
                        child: _NotificationTile(
                          item: n,
                          emphasized: true,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.crewRideInvite),
                        ),
                      ),
                    ),
                  ),
                  ...rest.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationTile(
                        item: n,
                        emphasized: false,
                        // Placeholder until there's a post-detail screen —
                        // hearts/comments point back at the Logbook feed.
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.feed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _NotifItem item;
  final bool emphasized;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.emphasized, required this.onTap});

  IconData get _typeIcon {
    switch (item.type) {
      case _NotifType.invite:
        return Icons.two_wheeler;
      case _NotifType.heart:
        return Icons.favorite;
      case _NotifType.comment:
        return Icons.mode_comment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.asphalt2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: emphasized ? AppColors.route : AppColors.asphalt3,
              width: emphasized ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppAvatar(initials: item.initials, color: item.color, size: 40),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: emphasized ? AppColors.route : AppColors.asphalt3,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.asphalt2, width: 2),
                    ),
                    child: Icon(_typeIcon,
                        size: 10, color: emphasized ? AppColors.darkInk : AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: AppText.body(size: 12, color: AppColors.inkDim)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.time, style: AppText.mono(size: 10, color: AppColors.inkDim)),
                if (emphasized) ...[
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.route),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft pulsing glow around ride-invite cards so they stand out above
/// the ordinary heart/comment notifications underneath.
class _PulsingGlow extends StatefulWidget {
  final Widget child;
  const _PulsingGlow({required this.child});

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _glow = Tween<double>(begin: 0.20, end: 0.65).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.route.withOpacity(_glow.value),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
