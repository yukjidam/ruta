import 'package:flutter/material.dart';

import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/stat_column.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.asphalt2,
                  border: Border(bottom: BorderSide(color: AppColors.asphalt3)),
                ),
                child: Row(
                  children: [
                    const AppAvatar(initials: 'JM', color: AppColors.route, size: 56, textColor: AppColors.darkInk),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Juan M.', style: AppText.display(size: 19)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              StatColumn(value: '1,204', label: 'km logged'),
                              StatColumn(value: '18', label: 'rides'),
                              StatColumn(value: '3', label: 'bikes'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text('My motorcycles',
                    style: AppText.mono(size: 11, color: AppColors.inkDim, letterSpacing: 2)),
              ),
              ...dummyBikes.map((bike) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.asphalt2,
                        border: Border.all(color: AppColors.asphalt3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: bike.color, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.two_wheeler, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bike.name, style: AppText.body(size: 14.5, weight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text('${bike.year} · ${bike.odometer}', style: AppText.mono(size: 11.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                child: DottedAddBikeCard(onTap: () {}),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class DottedAddBikeCard extends StatelessWidget {
  final VoidCallback onTap;
  const DottedAddBikeCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.asphalt3, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text('+ Register a motorcycle', style: AppText.mono(size: 12.5, color: AppColors.inkDim)),
      ),
    );
  }
}
