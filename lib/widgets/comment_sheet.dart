import 'package:flutter/material.dart';

import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_avatar.dart';

/// Opens a bottom sheet showing comments on a ride post, with a field to
/// add a new one. Comments posted here only live in this sheet's local
/// state — they're gone once it's dismissed. Swap for a real comments
/// table + realtime subscription later.
Future<void> showCommentSheet(BuildContext context, {required DummyRide ride}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.asphalt2,
    shape:
        const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _CommentSheet(ride: ride),
  );
}

class _CommentSheet extends StatefulWidget {
  final DummyRide ride;
  const _CommentSheet({required this.ride});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  late final List<DummyComment> _comments = List.of(widget.ride.commentList);

  void _post() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add(DummyComment(initials: 'JM', color: AppColors.route, name: 'You', text: text));
      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration:
                  BoxDecoration(color: AppColors.asphalt3, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
              child: Text(
                widget.ride.title,
                textAlign: TextAlign.center,
                style: AppText.body(size: 13.5, weight: FontWeight.w700),
              ),
            ),
            const Divider(color: AppColors.asphalt3, height: 1),
            Expanded(
              child: _comments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'No comments yet — be the first to say something.',
                          textAlign: TextAlign.center,
                          style: AppText.body(size: 12.5, color: AppColors.inkDim),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppAvatar(initials: c.initials, color: c.color, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: AppText.body(size: 12.5, weight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(c.text,
                                      style: AppText.body(size: 12.5, color: AppColors.inkDim)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.asphalt,
                        border: Border.all(color: AppColors.asphalt3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: AppText.body(size: 13),
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: AppText.body(size: 13, color: AppColors.inkDim),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _post(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                      onPressed: _post, icon: const Icon(Icons.send, color: AppColors.route)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
