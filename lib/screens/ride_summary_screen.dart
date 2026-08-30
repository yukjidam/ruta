import 'package:flutter/material.dart';

import '../main.dart';
import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/dashed_route_line.dart';

/// "Seal the Ride" — the composer shown right after Capture Memory.
/// The rider names the ride and adds a caption; distance/duration/riders
/// are read-only since they'll eventually come from the live GPS session,
/// not something typed in here. Saving is a stand-in for now (no backend
/// yet) — it just drops the rider back on the Feed.
///
/// Note: this screen is only reached from Capture Memory now. Tapping a
/// card in the Logbook opens RideDetailScreen instead — that's the
/// read-only viewer with the actual comment thread.
class RideSummaryScreen extends StatefulWidget {
  const RideSummaryScreen({super.key});

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen> {
  late DummyRide _ride;
  late final TextEditingController _titleController;
  late final TextEditingController _captionController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _ride = ModalRoute.of(context)?.settings.arguments as DummyRide? ?? dummyJustCompletedRide;
      _titleController = TextEditingController(text: _ride.title);
      _captionController = TextEditingController(text: _ride.caption);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _save() {
    // No backend yet, so there's nowhere real to persist the title/caption
    // typed above — this just simulates the "sealed into the logbook"
    // moment described in the README and drops the rider back on Feed.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your logbook!')),
    );
    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.feed));
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final distanceValue = ride.distanceLabel.split('·').first.trim();
    final riderCount = ride.riders.length;
    final riderCountLabel = riderCount == 1 ? '1 RIDER' : '$riderCount RIDERS';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 190,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5A6B57), Color(0xFF2F3A2C)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'SEAL THE RIDE',
                        textAlign: TextAlign.center,
                        style: AppText.mono(size: 11, color: Colors.white, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(
                        width: 48), // balances the back button so the label stays centered
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.paperLine)),
                      ),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              style: AppText.display(size: 24, color: AppColors.darkInk),
                              decoration: InputDecoration(
                                hintText: 'Name this ride',
                                hintStyle: AppText.display(size: 24, color: AppColors.darkInkDim),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit, size: 16, color: AppColors.darkInkDim),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${ride.date} · $riderCountLabel',
                        style: AppText.mono(size: 11, color: AppColors.darkInkDim)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                            width: 12,
                            height: 12,
                            decoration:
                                const BoxDecoration(color: AppColors.pine, shape: BoxShape.circle)),
                        Expanded(
                            child: DashedRouteLine(
                                color: AppColors.rust, dashWidth: 10, gapWidth: 6, height: 3)),
                        Container(
                            width: 12,
                            height: 12,
                            decoration:
                                const BoxDecoration(color: AppColors.rust, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.paperLine),
                          bottom: BorderSide(color: AppColors.paperLine),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SummaryStat(value: distanceValue, label: 'distance'),
                          _SummaryStat(value: ride.duration, label: 'duration'),
                          _SummaryStat(
                              value: '$riderCount', label: riderCount == 1 ? 'rider' : 'riders'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (var i = 0; i < ride.riders.length; i++)
                          Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 8, top: 14),
                            child: AppAvatar(
                              initials: ride.riders[i].initials,
                              color: ride.riders[i].color,
                              size: 30,
                              borderColor: AppColors.paper,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('CAPTION',
                        style: AppText.mono(size: 10, color: AppColors.route, letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.paperLine),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: TextField(
                        controller: _captionController,
                        minLines: 3,
                        maxLines: 6,
                        style: AppText.body(size: 13.5, color: AppColors.darkInk),
                        decoration: InputDecoration(
                          hintText: 'What made this ride memorable?',
                          hintStyle: AppText.body(size: 13.5, color: AppColors.darkInkDim),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    AppButton(label: 'Save to logbook', onPressed: _save, icon: Icons.check),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppText.mono(size: 17, color: AppColors.darkInk, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: AppText.mono(size: 9.5, color: AppColors.darkInkDim, letterSpacing: 1)),
      ],
    );
  }
}
