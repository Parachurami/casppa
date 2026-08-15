import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';

class AssessmentsEmptyState extends StatelessWidget {
  const AssessmentsEmptyState({
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onPressed,
    this.icon = Icons.assignment_outlined,
    super.key,
  });

  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: const BoxDecoration(
                color: AppColors.tagBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (ctaLabel != null && onPressed != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(label: ctaLabel!, onPressed: onPressed),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
