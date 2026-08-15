import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/status_pill.dart';
import 'package:casppa/app/core/widgets/tag_pill.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    required this.assignment,
    this.onTap,
    this.onEdit,
    super.key,
  });

  final AssignmentEntity assignment;

  /// Tapping the card body opens the assessment details / submissions page.
  final VoidCallback? onTap;

  /// The edit icon opens the edit/delete bottom sheet — locked once
  /// students have already submitted, so questions/details can't shift
  /// under work that's already been turned in.
  final VoidCallback? onEdit;

  bool get _hasSubmissions => assignment.submittedCount > 0;

  @override
  Widget build(BuildContext context) {
    final progress = assignment.expectedSubmissions == 0
        ? 0.0
        : assignment.submittedCount / assignment.expectedSubmissions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (assignment.className != null)
                            TagPill(label: assignment.className!),
                          if (assignment.subject != null)
                            TagPill(label: assignment.subject!),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_hasSubmissions) {
                          AppToast.info(
                            context,
                            "Can't edit — students have already submitted.",
                          );
                          return;
                        }
                        onEdit?.call();
                      },
                      icon: Icon(
                        _hasSubmissions
                            ? Icons.lock_outline
                            : Icons.edit_outlined,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                      color: AppColors.textPrimary,
                    ),
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
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Submissions',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${assignment.submittedCount}/${assignment.expectedSubmissions}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.progressFill,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      assignment.dueDate == null
                          ? 'No due date'
                          : 'Due ${formatShortDate(assignment.dueDate!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (assignment.isOverdue)
                      const StatusPill(
                        label: 'Overdue',
                        background: AppColors.statusOverdueBackground,
                        textColor: AppColors.statusOverdueText,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
