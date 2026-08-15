import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';

enum AssessmentTab { assignments, cbtExams, quickTests }

class AssessmentTypeTabs extends StatelessWidget {
  const AssessmentTypeTabs({
    required this.selected,
    required this.onChanged,
    this.counts = const {},
    super.key,
  });

  final AssessmentTab selected;
  final ValueChanged<AssessmentTab> onChanged;
  final Map<AssessmentTab, int> counts;

  static const _labels = {
    AssessmentTab.assignments: 'Assignments',
    AssessmentTab.cbtExams: 'CBT Exams',
    AssessmentTab.quickTests: 'Quick Tests',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Row(
        children: AssessmentTab.values.map((tab) {
          final isSelected = tab == selected;
          final count = counts[tab] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onChanged(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _labels[tab]!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
