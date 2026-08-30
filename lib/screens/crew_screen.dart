import 'package:flutter/material.dart';

import '../main.dart';
import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_bottom_nav.dart';

class CrewScreen extends StatefulWidget {
  const CrewScreen({super.key});

  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
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
    final people = dummyProfiles.where((p) {
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crew', style: AppText.display(size: 24)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.asphalt2,
                      border: Border.all(color: AppColors.asphalt3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: AppText.body(size: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Search by name or @username…',
                        hintStyle: AppText.body(size: 12.5, color: AppColors.inkDim),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: people.isEmpty
                  ? Center(
                      child: Text('No riders match "$_query".',
                          style: AppText.body(size: 12.5, color: AppColors.inkDim)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: people.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.asphalt3, height: 1),
                      itemBuilder: (context, i) {
                        final person = people[i];
                        return InkWell(
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.profile, arguments: person),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Row(
                              children: [
                                AppAvatar(initials: person.initials, color: person.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(person.name,
                                          style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                                      Text(person.username, style: AppText.mono(size: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: person.isFriend ? AppColors.route : AppColors.asphalt3,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    person.isFriend ? 'Invited' : 'Add',
                                    style: AppText.mono(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: person.isFriend ? AppColors.darkInk : AppColors.inkDim,
                                    ),
                                  ),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
