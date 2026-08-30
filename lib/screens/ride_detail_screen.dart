import 'package:flutter/material.dart';

import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/dashed_route_line.dart';

/// Read-only viewer for a ride that's already in the logbook — reached by
/// tapping a card on the Feed (or, later, a Profile). Shows the caption
/// and comment thread the composer (RideSummaryScreen) doesn't need to,
/// since a ride can't have comments before it's posted.
///
/// Uses a plain Navigator.pop() to go back, so it always returns to
/// wherever it was opened from (Feed or a friend's Profile) rather than
/// forcing a jump to Feed.
class RideDetailScreen extends StatefulWidget {
  const RideDetailScreen({super.key});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  late DummyRide _ride;
  late bool _hearted;
  late int _heartCount;
  late List<DummyComment> _comments;
  final _commentController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _ride = ModalRoute.of(context)?.settings.arguments as DummyRide? ?? dummyRides.first;
      _hearted = _ride.heartedByMe;
      _heartCount = _ride.hearts;
      _comments = List.of(_ride.commentList);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleHeart() {
    setState(() {
      _hearted = !_hearted;
      _heartCount += _hearted ? 1 : -1;
    });
  }

  void _postComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add(DummyComment(initials: 'JM', color: AppColors.route, name: 'You', text: text));
      _commentController.clear();
    });
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      children: [
                        Text(ride.title,
                            style: AppText.display(size: 24, color: AppColors.darkInk)),
                        const SizedBox(height: 4),
                        Text('${ride.date} · $riderCountLabel',
                            style: AppText.mono(size: 11, color: AppColors.darkInkDim)),
                        if (ride.caption.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(ride.caption,
                              style: AppText.body(size: 13.5, color: AppColors.darkInk)
                                  .copyWith(height: 1.5)),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                    color: AppColors.pine, shape: BoxShape.circle)),
                            Expanded(
                                child: DashedRouteLine(
                                    color: AppColors.rust, dashWidth: 10, gapWidth: 6, height: 3)),
                            Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                    color: AppColors.rust, shape: BoxShape.circle)),
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
                                  value: '$riderCount',
                                  label: riderCount == 1 ? 'rider' : 'riders'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              for (var i = 0; i < ride.riders.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                                  child: AppAvatar(
                                    initials: ride.riders[i].initials,
                                    color: ride.riders[i].color,
                                    size: 30,
                                    borderColor: AppColors.paper,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
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
                                      size: 20,
                                      color: _hearted ? AppColors.rust : AppColors.darkInkDim,
                                    ),
                                    const SizedBox(width: 6),
                                    Text('$_heartCount',
                                        style: AppText.mono(
                                            size: 12.5,
                                            color: AppColors.darkInkDim,
                                            weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.mode_comment_outlined,
                                      size: 19, color: AppColors.darkInkDim),
                                  const SizedBox(width: 6),
                                  Text('${_comments.length}',
                                      style: AppText.mono(
                                          size: 12.5,
                                          color: AppColors.darkInkDim,
                                          weight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.paperLine, height: 26),
                        Text('COMMENTS',
                            style:
                                AppText.mono(size: 10, color: AppColors.route, letterSpacing: 1.5)),
                        const SizedBox(height: 14),
                        if (_comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No comments yet — be the first to say something.',
                              style: AppText.body(size: 12.5, color: AppColors.darkInkDim),
                            ),
                          )
                        else
                          for (final c in _comments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppAvatar(initials: c.initials, color: c.color, size: 30),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name,
                                            style: AppText.body(
                                                size: 12.5,
                                                weight: FontWeight.w700,
                                                color: AppColors.darkInk)),
                                        const SizedBox(height: 2),
                                        Text(c.text,
                                            style: AppText.body(
                                                size: 12.5, color: AppColors.darkInkDim)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      border: Border(top: BorderSide(color: AppColors.paperLine)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.paperLine),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _commentController,
                              style: AppText.body(size: 13, color: AppColors.darkInk),
                              decoration: InputDecoration(
                                hintText: 'Add a comment…',
                                hintStyle: AppText.body(size: 13, color: AppColors.darkInkDim),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (_) => _postComment(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                            onPressed: _postComment,
                            icon: const Icon(Icons.send, color: AppColors.route)),
                      ],
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
