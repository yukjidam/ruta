import 'package:flutter/material.dart';

import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_avatar.dart';
import 'comment_sheet.dart';

/// A single ride entry in a logbook — used identically on the Feed and on
/// any Profile screen (yours or a friend's), so heart/comment behavior
/// and the visual card look the same no matter where a ride shows up.
///
/// Heart state is local to this widget for now (setState only) since
/// there's no backend to persist it against yet.
class RidePostCard extends StatefulWidget {
  final DummyRide ride;
  final VoidCallback? onTap;

  const RidePostCard({super.key, required this.ride, this.onTap});

  @override
  State<RidePostCard> createState() => _RidePostCardState();
}

class _RidePostCardState extends State<RidePostCard> {
  static const _gradients = [
    [Color(0xFF5A6B57), Color(0xFF2F3A2C)],
    [Color(0xFF6B5A45), Color(0xFF2E241A)],
    [Color(0xFF3E5A66), Color(0xFF1D2B30)],
    [Color(0xFF6B4A57), Color(0xFF2A1E24)],
  ];

  late bool _hearted;
  late int _heartCount;

  @override
  void initState() {
    super.initState();
    _hearted = widget.ride.heartedByMe;
    _heartCount = widget.ride.hearts;
  }

  void _toggleHeart() {
    setState(() {
      _hearted = !_hearted;
      _heartCount += _hearted ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final gradient = _gradients[ride.title.hashCode.abs() % _gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(ride.distanceLabel,
                        style: AppText.mono(size: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.title,
                    style:
                        AppText.body(size: 15, weight: FontWeight.w700, color: AppColors.darkInk)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(ride.date, style: AppText.mono(size: 10.5, color: AppColors.darkInkDim)),
                    const SizedBox(width: 10),
                    Text(ride.duration,
                        style: AppText.mono(size: 10.5, color: AppColors.darkInkDim)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 0; i < ride.riders.length; i++)
                      Transform.translate(
                        offset: Offset(i == 0 ? 0 : -8.0 * i, 0),
                        child: AppAvatar(
                          initials: ride.riders[i].initials,
                          color: ride.riders[i].color,
                          size: 26,
                          borderColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.paperLine, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _toggleHeart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _hearted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: _hearted ? AppColors.rust : AppColors.darkInkDim,
                        ),
                        const SizedBox(width: 5),
                        Text('$_heartCount',
                            style: AppText.mono(
                                size: 11.5, color: AppColors.darkInkDim, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => showCommentSheet(context, ride: ride),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.mode_comment_outlined,
                            size: 17, color: AppColors.darkInkDim),
                        const SizedBox(width: 5),
                        Text('${ride.comments}',
                            style: AppText.mono(
                                size: 11.5, color: AppColors.darkInkDim, weight: FontWeight.w600)),
                      ],
                    ),
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
