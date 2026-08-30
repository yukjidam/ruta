import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: AppColors.inkDim),
                style: IconButton.styleFrom(backgroundColor: AppColors.asphalt2),
              ),
              const SizedBox(height: 14),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  // Sampled from the reference icon (#F5B700) — move this
                  // into AppColors as the official brand yellow whenever
                  // you're ready to reuse it elsewhere.
                  color: const Color(0xFFF5B700),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'R',
                  style: AppText.display(size: 28, color: AppColors.asphalt),
                ),
              ),
              const SizedBox(height: 14),
              Text('Welcome\nback', style: AppText.display(size: 30)),
              const SizedBox(height: 8),
              Text(
                'Log in to see your crew and pick up where you parked.',
                style: AppText.body(size: 12.5, color: AppColors.inkDim).copyWith(height: 1.5),
              ),
              const SizedBox(height: 22),
              const AppTextField(label: 'Email or username', hint: '@juanmrides'),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Password',
                hint: '••••••••••',
                obscure: true,
                trailing: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.inkDim),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: Text('Forgot password?',
                      style: AppText.mono(size: 11, color: AppColors.route)),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Log in',
                onPressed: () =>
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.feed, (route) => false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.asphalt3)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: AppText.mono(size: 10, color: AppColors.inkDim)),
                  ),
                  const Expanded(child: Divider(color: AppColors.asphalt3)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.asphalt3),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('Continue with Google', style: AppText.body(size: 13)),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                  child: RichText(
                    text: TextSpan(
                      style: AppText.body(size: 12.5, color: AppColors.inkDim),
                      children: [
                        const TextSpan(text: 'New here? '),
                        TextSpan(
                          text: 'Create a logbook',
                          style: AppText.body(
                              size: 12.5, color: AppColors.route, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
