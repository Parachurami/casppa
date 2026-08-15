import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    required this.selectedRole,
    required this.onChanged,
    this.roles = const [UserRole.teacher, UserRole.student, UserRole.parent],
    super.key,
  });

  final UserRole? selectedRole;
  final ValueChanged<UserRole> onChanged;
  final List<UserRole> roles;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: roles.map((role) {
        final isSelected = role == selectedRole;
        return ChoiceChip(
          label: Text(_labelFor(role)),
          selected: isSelected,
          onSelected: (_) => onChanged(role),
          showCheckmark: false,
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  String _labelFor(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
