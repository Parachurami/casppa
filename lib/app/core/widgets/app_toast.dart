import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';

class AppToast {
  const AppToast._();

  static void success(BuildContext context, String message) {
    _show(context, message: message, type: ToastificationType.success, color: AppColors.secondary);
  }

  static void error(BuildContext context, String message) {
    _show(context, message: message, type: ToastificationType.error, color: AppColors.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message: message, type: ToastificationType.info, color: AppColors.primary);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required ToastificationType type,
    required Color color,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      primaryColor: color,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [],
      showProgressBar: false,
      title: Text(message, style: AppTextStyles.body),
    );
  }
}
