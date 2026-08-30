import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_button.dart';

class PausedRideScreen extends StatelessWidget {
  const PausedRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF26382C), Color(0xFF22322A)],
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.72)),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: AppColors.route, shape: BoxShape.circle),
                      child: const Icon(Icons.pause, color: AppColors.darkInk, size: 26),
                    ),
                    const SizedBox(height: 18),
                    Text('Ride paused', style: AppText.display(size: 24)),
                    const SizedBox(height: 6),
                    Text(
                      "Juan called a rest stop.\nEveryone's position is holding.",
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 12.5, color: AppColors.inkDim).copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 26),
                    Text('08:42', style: AppText.mono(size: 30, color: AppColors.route, weight: FontWeight.w700)),
                    const SizedBox(height: 26),
                    AppButton(label: 'Resume ride', onPressed: () => Navigator.pop(context)),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'End ride here instead',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
