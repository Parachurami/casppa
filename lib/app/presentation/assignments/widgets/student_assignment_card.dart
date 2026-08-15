import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/tag_pill.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';

class StudentAssignmentCard extends StatelessWidget {
  const StudentAssignmentCard({
    required this.assignment,
    this.onSubmit,
    this.onViewFeedback,
    super.key,
  });

  final StudentAssignmentEntity assignment;
  final VoidCallback? onSubmit;
  final VoidCallback? onViewFeedback;

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
              ..._statusTag(),
            ],
          ),
          const SizedBox(height: 12),
          Text(assignment.title, style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(
            assignment.description?.isNotEmpty == true
                ? assignment.description!
                : 'No description provided.',
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

  List<Widget> _statusTag() {
    switch (assignment.submissionStatus) {
      case StudentSubmissionStatus.submitted:
      case StudentSubmissionStatus.resubmitted:
        return const [
          TagPill(
            label: 'Submitted',
            background: AppColors.tagBackground,
            textColor: AppColors.tagText,
          ),
        ];
      case StudentSubmissionStatus.returned:
        return const [
          TagPill(
            label: 'Graded',
            background: AppColors.gradedBackground,
            textColor: AppColors.gradedText,
          ),
        ];
      case StudentSubmissionStatus.notSubmitted:
        if (assignment.isOverdue) {
          return const [
            TagPill(
              label: 'Overdue',
              background: AppColors.statusOverdueBackground,
              textColor: AppColors.statusOverdueText,
            ),
          ];
        }
        return const [];
    }
  }

  Widget _buildAction() {
    switch (assignment.submissionStatus) {
      case StudentSubmissionStatus.submitted:
      case StudentSubmissionStatus.resubmitted:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Awaiting Grade',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case StudentSubmissionStatus.returned:
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onViewFeedback,
            child: const Text('View Feedback'),
          ),
        );
      case StudentSubmissionStatus.notSubmitted:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Submit'),
          ),
        );
    }
  }
}
