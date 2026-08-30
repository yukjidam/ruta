import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/section_eyebrow.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final List<Map<String, Object>> _riders = [
    {
      'initials': 'JM',
      'color': AppColors.route,
      'name': 'Juan (you)',
      'sub': 'Leader',
      'ready': true
    },
    {
      'initials': 'KR',
      'color': AppColors.pine,
      'name': 'Kim Reyes',
      'sub': 'Mio Sporty',
      'ready': true
    },
    {'initials': 'MT', 'color': AppColors.rust, 'name': 'Mar Tan', 'sub': 'CB150R', 'ready': true},
    {
      'initials': 'AL',
      'color': AppColors.asphalt3,
      'name': 'Al Santos',
      'sub': 'Joining…',
      'ready': false
    },
  ];

  int get _readyCount => _riders.where((r) => r['ready'] as bool).length;
  bool get _allReady => _readyCount == _riders.length;

  // Leader tapped "Start the ride" — if someone isn't ready yet, confirm
  // first; otherwise go straight to the countdown.
  Future<void> _handleStartPressed() async {
    if (_allReady) {
      _startCountdown();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _NotReadyDialog(notReadyCount: _riders.length - _readyCount),
    );
    if (confirmed == true) _startCountdown();
  }

  Future<void> _startCountdown() async {
    final started = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _StartCountdownDialog(seconds: 5),
    );
    if (started == true && mounted) {
      Navigator.pushNamed(context, AppRoutes.liveRide);
    }
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
                  const SectionEyebrow(text: 'Waiting to ride'),
                  const SizedBox(height: 10),
                  Text('Tagaytay Ridge', style: AppText.display(size: 24)),
                  const SizedBox(height: 4),
                  Text('$_readyCount of ${_riders.length} riders ready',
                      style: AppText.body(size: 12.5, color: AppColors.inkDim)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: _riders.map((r) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        AppAvatar(
                            initials: r['initials'] as String,
                            color: r['color'] as Color,
                            size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['name'] as String,
                                  style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                              Text(r['sub'] as String, style: AppText.mono(size: 11)),
                            ],
                          ),
                        ),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (r['ready'] as bool)
                                ? AppColors.success
                                : AppColors.inkDim.withOpacity(0.4),
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
              child: AppButton(
                label: 'Start the ride',
                onPressed: _handleStartPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the leader tries to start while at least one rider hasn't
/// joined yet. Blocks the countdown until they explicitly confirm.
class _NotReadyDialog extends StatelessWidget {
  final int notReadyCount;
  const _NotReadyDialog({required this.notReadyCount});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.asphalt2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.rust, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text('Not everyone is ready', style: AppText.display(size: 16))),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              notReadyCount == 1
                  ? "1 rider hasn't joined yet. Start the ride without them?"
                  : "$notReadyCount riders haven't joined yet. Start the ride without them?",
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
                    child: Text('Wait', style: AppText.body(size: 13, weight: FontWeight.w700)),
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
                    child: Text('Start anyway',
                        style:
                            AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full 5-second countdown before the ride actually starts. Leader can
/// still back out with "Cancel" while it's running.
class _StartCountdownDialog extends StatefulWidget {
  final int seconds;
  const _StartCountdownDialog({required this.seconds});

  @override
  State<_StartCountdownDialog> createState() => _StartCountdownDialogState();
}

class _StartCountdownDialogState extends State<_StartCountdownDialog> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (_remaining <= 1) {
      timer.cancel();
      Navigator.pop(context, true);
      return;
    }
    setState(() => _remaining--);
  }

  void _cancel() {
    _timer?.cancel();
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.asphalt2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RIDE STARTING',
                  style: AppText.mono(size: 11, color: AppColors.inkDim, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(
                '$_remaining',
                style: AppText.display(size: 64).copyWith(color: AppColors.route),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _cancel,
                child: Text('Cancel', style: AppText.body(size: 13, color: AppColors.inkDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
