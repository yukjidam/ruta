import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_button.dart';
import '../widgets/dashed_route_line.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: Stack(
          children: [
            // Signature route-line motif, angled across the screen.
            Positioned(
              bottom: 260,
              left: -40,
              right: -40,
              child: Transform.rotate(
                angle: -0.07,
                child: const DashedRouteLine(dashWidth: 20, gapWidth: 16, height: 3),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.route,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('R', style: AppText.display(size: 24, color: AppColors.darkInk)),
                    ),
                    Text('Every ride,\nremembered.', style: AppText.display(size: 42)),
                    const SizedBox(height: 12),
                    Text(
                      "Track the road live with your crew, then seal each ride into your logbook with a photo.",
                      style: AppText.body(size: 13.5, color: AppColors.inkDim, weight: FontWeight.w400)
                          .copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 26),
                    AppButton(
                      label: 'Start your logbook',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'I already ride here',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                    ),
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
