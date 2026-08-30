import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
              Text('Create your\nlogbook', style: AppText.display(size: 30)),
              const SizedBox(height: 8),
              Text(
                "You'll use this to log in, get invited to rides, and register your bikes.",
                style: AppText.body(size: 12.5, color: AppColors.inkDim).copyWith(height: 1.5),
              ),
              const SizedBox(height: 22),
              const AppTextField(label: 'Full name', hint: 'Juan Miguel'),
              const SizedBox(height: 14),
              const AppTextField(label: 'Username', hint: '@juanmrides'),
              const SizedBox(height: 14),
              const AppTextField(label: 'Email', hint: 'juan@email.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Password',
                hint: '••••••••••',
                obscure: true,
                trailing: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.inkDim),
              ),
              const SizedBox(height: 26),
              AppButton(
                label: 'Create account',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.feed, (route) => false),
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: RichText(
                    text: TextSpan(
                      style: AppText.body(size: 12.5, color: AppColors.inkDim),
                      children: [
                        const TextSpan(text: 'Already ride with us? '),
                        TextSpan(
                          text: 'Log in',
                          style: AppText.body(size: 12.5, color: AppColors.route, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'By continuing you agree to the Terms\nand acknowledge the Privacy Policy.',
                textAlign: TextAlign.center,
                style: AppText.mono(size: 9.5, color: AppColors.inkDim).copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
