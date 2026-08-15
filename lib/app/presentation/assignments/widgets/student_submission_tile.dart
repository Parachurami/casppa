import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/status_pill.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';

class StudentSubmissionTile extends StatelessWidget {
  const StudentSubmissionTile({
    required this.submission,
    this.onOpenMarkingView,
    this.totalPoints = 100,
    this.readOnly = false,
    super.key,
  });

  final StudentSubmissionEntity submission;
  final VoidCallback? onOpenMarkingView;
  final int totalPoints;

  /// Admin oversight mode — hides the grading action entirely.
  final bool readOnly;

  bool get _isGraded => submission.finalScore != null;
  bool get _isReturned =>
      submission.status == StudentSubmissionStatus.returned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  initialsFromName(submission.studentName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(submission.studentName, style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      submission.submittedAt == null
                          ? 'Not submitted'
                          : 'Submitted ${formatShortDate(submission.submittedAt!)}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderPill(),
            ],
          ),
          if (submission.bodyText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(submission.bodyText!, style: AppTextStyles.body),
            ),
          ],
          if (submission.attachmentFileName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    submission.attachmentFileName!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_isGraded && !_isReturned) ...[
            const SizedBox(height: 8),
            Text(
              'Graded — not yet returned to student',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (submission.statusLabel == GradeStatus.needsRevision) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const StatusPill(
                  label: 'Needs Revision',
                  background: AppColors.revisionBackground,
                  textColor: AppColors.revisionText,
                ),
                if (_isReturned)
                  const StatusPill(
                    label: 'Awaiting resubmission',
                    background: AppColors.pendingBackground,
                    textColor: AppColors.pendingText,
                  ),
              ],
            ),
          ],
          if (!readOnly &&
              submission.status != StudentSubmissionStatus.notSubmitted) ...[
            const SizedBox(height: 12),
            _buildAction(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderPill() {
    if (submission.status == StudentSubmissionStatus.notSubmitted) {
      return const StatusPill(
        label: 'Pending',
        background: AppColors.pendingBackground,
        textColor: AppColors.pendingText,
      );
    }

    if (_isGraded) {
      return StatusPill(
        label: '${submission.finalScore}/$totalPoints',
        background: AppColors.gradedBackground,
        textColor: AppColors.gradedText,
      );
    }

    return const StatusPill(
      label: 'To grade',
      background: AppColors.revisionBackground,
      textColor: AppColors.revisionText,
    );
  }

  Widget _buildAction() {
    if (submission.status == StudentSubmissionStatus.notSubmitted) {
      return const SizedBox.shrink();
    }

    if (_isGraded) {
      return InkWell(
        onTap: onOpenMarkingView,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'View / Re-mark',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onOpenMarkingView,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Open Full Marking View'),
      ),
    );
  }
}
