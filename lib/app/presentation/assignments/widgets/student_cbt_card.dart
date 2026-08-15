import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/tag_pill.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';

class StudentCbtCard extends StatelessWidget {
  const StudentCbtCard({
    required this.assignment,
    this.onStart,
    this.onViewResults,
    super.key,
  });

  final StudentAssignmentEntity assignment;
  final VoidCallback? onStart;
  final VoidCallback? onViewResults;

  bool get _isSubmitted =>
      assignment.submissionStatus != StudentSubmissionStatus.notSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (assignment.subject != null)
                TagPill(
                  label: assignment.subject!,
                  background: AppColors.pendingBackground,
                  textColor: AppColors.pendingText,
                ),
              if (_isSubmitted)
                TagPill(
                  label:
                      assignment.submissionStatus ==
                          StudentSubmissionStatus.returned
                      ? 'Graded'
                      : 'Completed',
                  background:
                      assignment.submissionStatus ==
                          StudentSubmissionStatus.returned
                      ? AppColors.gradedBackground
                      : AppColors.tagBackground,
                  textColor:
                      assignment.submissionStatus ==
                          StudentSubmissionStatus.returned
                      ? AppColors.gradedText
                      : AppColors.tagText,
                )
              else if (assignment.isOverdue)
                const TagPill(
                  label: 'Overdue',
                  background: AppColors.statusOverdueBackground,
                  textColor: AppColors.statusOverdueText,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(assignment.title, style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(
            assignment.description?.isNotEmpty == true
                ? assignment.description!
                : 'No instructions provided.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: assignment.dueDate == null
                      ? 'No due date'
                      : 'Due ${formatLongDate(assignment.dueDate!)}',
                ),
                const TextSpan(text: ' · '),
                TextSpan(
                  text: assignment.teacherName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAction(),
        ],
      ),
    );
  }

  Widget _buildAction() {
    if (_isSubmitted) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onViewResults,
          child: const Text('View Results'),
        ),
      );
    }

    if (assignment.isOverdue) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.statusOverdueBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Overdue — can no longer be started',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.statusOverdueText,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text('Start Test'),
      ),
    );
  }
}
