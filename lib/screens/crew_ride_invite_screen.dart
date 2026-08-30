import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/section_eyebrow.dart';

/// What a crew member sees after tapping a ride-invite notification —
/// the counterpart to lobby_screen.dart, which is the leader's view of
/// the same waiting room. Same rider list, but the controls are
/// different: no "Start the ride" (only the leader can do that), just
/// a ready toggle and the option to back out.
class CrewRideInviteScreen extends StatefulWidget {
  const CrewRideInviteScreen({super.key});

  @override
  State<CrewRideInviteScreen> createState() => _CrewRideInviteScreenState();
}

class _CrewRideInviteScreenState extends State<CrewRideInviteScreen> {
  // "you" are Mar Tan here, not ready yet — toggled locally below.
  bool _iAmReady = false;

  late final List<Map<String, Object>> _riders = [
    {'initials': 'JM', 'color': AppColors.route, 'name': 'Juan Miguel', 'sub': 'Leader', 'ready': true, 'isLeader': true, 'isYou': false},
    {'initials': 'KR', 'color': AppColors.pine, 'name': 'Kim Reyes', 'sub': 'Mio Sporty', 'ready': true, 'isLeader': false, 'isYou': false},
    {'initials': 'MT', 'color': AppColors.rust, 'name': 'Mar Tan (you)', 'sub': 'CB150R', 'ready': false, 'isLeader': false, 'isYou': true},
    {'initials': 'AL', 'color': AppColors.asphalt3, 'name': 'Al Santos', 'sub': 'Joining…', 'ready': false, 'isLeader': false, 'isYou': false},
  ];

  bool _isReady(Map<String, Object> r) => (r['isYou'] as bool) ? _iAmReady : r['ready'] as bool;

  int get _readyCount => _riders.where(_isReady).length;

  void _toggleReady() => setState(() => _iAmReady = !_iAmReady);

  Future<void> _declineInvite() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.asphalt2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Decline this ride?', style: AppText.display(size: 16)),
              const SizedBox(height: 8),
              Text(
                "Juan and the crew won't be notified — you'll just drop off the list.",
                style: AppText.body(size: 13, color: AppColors.inkDim).copyWith(height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.inkDim),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Stay', style: AppText.body(size: 13, weight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rust,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Decline', style: AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Column(
                children: [
                  const SectionEyebrow(text: "You're invited"),
                  const SizedBox(height: 10),
                  Text('Tagaytay Ridge', style: AppText.display(size: 24)),
                  const SizedBox(height: 4),
                  Text('$_readyCount of ${_riders.length} riders ready', style: AppText.body(size: 12.5, color: AppColors.inkDim)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: _riders.map((r) {
                  final ready = _isReady(r);
                  final isLeader = r['isLeader'] as bool;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        AppAvatar(initials: r['initials'] as String, color: r['color'] as Color, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(r['name'] as String, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                                  if (isLeader) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.star, size: 12, color: AppColors.route),
                                  ],
                                ],
                              ),
                              Text(r['sub'] as String, style: AppText.mono(size: 11)),
                            ],
                          ),
                        ),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ready ? AppColors.success : AppColors.inkDim.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
              child: Column(
                children: [
                  Text(
                    _iAmReady ? 'Waiting for Juan to start the ride…' : 'Let the crew know when you\'re set',
                    style: AppText.body(size: 12, color: AppColors.inkDim),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: _iAmReady
                        ? OutlinedButton.icon(
                            onPressed: _toggleReady,
                            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                            label: Text("You're ready", style: AppText.body(size: 14, weight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.success),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        : AppButton(label: "I'm ready", onPressed: _toggleReady),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _declineInvite,
                    child: Text('Decline invite', style: AppText.body(size: 12.5, color: AppColors.inkDim)),
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
