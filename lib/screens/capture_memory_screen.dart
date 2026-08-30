import 'package:flutter/material.dart';

import '../main.dart';
import '../models/dummy_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class CaptureMemoryScreen extends StatelessWidget {
  const CaptureMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A5A44), Color(0xFF232B20)],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "You've arrived. Snap a photo to\nseal this ride in your logbook.",
                          textAlign: TextAlign.center,
                          style: AppText.body(size: 13, color: AppColors.ink).copyWith(height: 1.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.asphalt2,
                      border: Border.all(color: AppColors.asphalt3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.inkDim),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.rideSummary,
                      arguments: dummyJustCompletedRide,
                    ),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.route,
                        border: Border.all(color: AppColors.ink, width: 4),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.asphalt2,
                      border: Border.all(color: AppColors.asphalt3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.cameraswitch_outlined, size: 18, color: AppColors.inkDim),
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
