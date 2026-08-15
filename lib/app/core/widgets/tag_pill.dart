import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';

class TagPill extends StatelessWidget {
  const TagPill({
    required this.label,
    this.background = AppColors.tagBackground,
    this.textColor = AppColors.tagText,
    super.key,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
