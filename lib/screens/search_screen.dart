import 'package:flutter/material.dart';

import '../main.dart';
import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';

/// Search across every rider account in the app (crew or not). Filtering
/// happens client-side over dummyProfiles for now — swap for a Supabase
/// query (ilike on name/username) once the backend exists.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = dummyProfiles.where((p) {
      if (p.id == 'me') return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.username.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.inkDim),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.asphalt2,
                        border: Border.all(color: AppColors.asphalt3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: AppText.body(size: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Search riders by name or @username',
                          hintStyle: AppText.body(size: 12.5, color: AppColors.inkDim),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty
                            ? 'Start typing to find riders.'
                            : 'No riders match "$_query".',
                        style: AppText.body(size: 12.5, color: AppColors.inkDim),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.asphalt3, height: 1),
                      itemBuilder: (context, i) {
                        final p = results[i];
                        return InkWell(
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.profile, arguments: p),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                AppAvatar(initials: p.initials, color: p.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name,
                                          style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                                      Text(p.username, style: AppText.mono(size: 11)),
                                    ],
                                  ),
                                ),
                                if (p.isFriend)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: AppColors.route,
                                        borderRadius: BorderRadius.circular(20)),
                                    child: Text('Crew',
                                        style: AppText.mono(
                                            size: 9.5,
                                            weight: FontWeight.w700,
                                            color: AppColors.darkInk)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
