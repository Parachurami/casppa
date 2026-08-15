import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({required this.data, super.key});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 160,
            width: 160,
            decoration: const BoxDecoration(
              color: AppColors.tagBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 72, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
