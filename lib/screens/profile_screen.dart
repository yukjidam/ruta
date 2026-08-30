import 'package:flutter/material.dart';

import '../main.dart';
import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/ride_post_card.dart';
import '../widgets/stat_column.dart';

/// A single profile screen used for both "you" and any friend or searched
/// rider — the DummyProfile to show is passed in as route arguments.
/// Falls back to the signed-in user if none is provided, so it never
/// crashes if pushed without arguments during development.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local-only: whether a friend request has been sent to the profile
  // being viewed *this session*. Resets on navigation, same as the heart
  // state on RidePostCard — there's no friend_requests table yet, so
  // this just proves out the interaction until Phase 6 wires up Supabase.
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final profile = args is DummyProfile ? args : dummyProfiles.firstWhere((p) => p.id == 'me');
    final isSelf = profile.id == 'me';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: AppColors.darkInk),
                    ),
                    if (!isSelf)
                      GestureDetector(
                        onTap: profile.isFriend
                            ? null
                            : () => setState(() => _requested = !_requested),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: profile.isFriend ? AppColors.route : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _requested && !profile.isFriend
                                  ? AppColors.route
                                  : AppColors.paperLine,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_requested && !profile.isFriend) ...[
                                const Icon(Icons.schedule, size: 12, color: AppColors.route),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                profile.isFriend
                                    ? 'Invited'
                                    : (_requested ? 'Requested' : 'Add friend'),
                                style: AppText.mono(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: profile.isFriend
                                      ? AppColors.darkInk
                                      : (_requested ? AppColors.route : AppColors.darkInkDim),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                child: Column(
                  children: [
                    AppAvatar(
                        initials: profile.initials,
                        color: profile.color,
                        size: 72,
                        textColor: AppColors.darkInk),
                    const SizedBox(height: 12),
                    Text(profile.name, style: AppText.display(size: 22, color: AppColors.darkInk)),
                    const SizedBox(height: 2),
                    Text(profile.username,
                        style: AppText.mono(size: 12, color: AppColors.darkInkDim)),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatColumn(
                          value: profile.kmLogged,
                          label: 'km logged',
                          valueColor: AppColors.rust,
                          labelColor: AppColors.darkInkDim,
                        ),
                        StatColumn(
                          value: profile.ridesCount,
                          label: 'rides',
                          valueColor: AppColors.rust,
                          labelColor: AppColors.darkInkDim,
                        ),
                        StatColumn(
                          value: '${profile.bikes.length}',
                          label: 'bikes',
                          valueColor: AppColors.rust,
                          labelColor: AppColors.darkInkDim,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (profile.bikes.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: profile.bikes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final b = profile.bikes[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        alignment: Alignment.center,
                        child: Text('${b.name} · ${b.year}',
                            style: AppText.body(
                                size: 11.5, weight: FontWeight.w600, color: AppColors.darkInk)),
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Text('Logbook',
                    style: AppText.mono(size: 11, color: AppColors.darkInkDim, letterSpacing: 2)),
              ),
            ),
            if (profile.rides.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No rides logged yet.',
                        style: AppText.body(size: 12.5, color: AppColors.darkInkDim)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => RidePostCard(
                      ride: profile.rides[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.rideDetail,
                        arguments: profile.rides[i],
                      ),
                    ),
                    childCount: profile.rides.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
