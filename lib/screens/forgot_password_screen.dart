import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: Padding(
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
              Text('Reset your\npassword', style: AppText.display(size: 30)),
              const SizedBox(height: 8),
              Text(
                "Enter the email on your account and we'll send a reset link.",
                style: AppText.body(size: 12.5, color: AppColors.inkDim).copyWith(height: 1.5),
              ),
              const SizedBox(height: 22),
              const AppTextField(label: 'Email', hint: 'juan@email.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 26),
              AppButton(label: 'Send reset link', onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: AppText.body(size: 12.5, color: AppColors.inkDim),
                      children: [
                        const TextSpan(text: 'Remembered it? '),
                        TextSpan(
                          text: 'Back to log in',
                          style: AppText.body(size: 12.5, color: AppColors.route, weight: FontWeight.w700),
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
