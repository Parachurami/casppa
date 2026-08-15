import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/core/widgets/status_pill.dart';
import 'package:casppa/app/core/widgets/tag_pill.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/submit_assignment_dialog.dart';

class StudentFeedbackPage extends ConsumerWidget {
  const StudentFeedbackPage({required this.assignment, super.key});

  final StudentAssignmentEntity assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionId = assignment.submissionId;

    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (assignment.subject != null)
                    TagPill(label: assignment.subject!),
                  if (assignment.dueDate != null)
                    TagPill(
                      label: 'Due ${formatLongDate(assignment.dueDate!)}',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Your submission', style: AppTextStyles.title),
              const SizedBox(height: 8),
              if (submissionId == null)
                Text(
                  'No submission found.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Consumer(
                  builder: (context, ref, _) {
                    final annotationsState = ref.watch(
                      submissionAnnotationsProvider(submissionId),
                    );

                    return annotationsState.when(
                      loading: () => AspectRatio(
                        aspectRatio: 1400 / 2176,
                        child: ShimmerGroup(
                          child: SkeletonBox(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 14,
                          ),
                        ),
                      ),
                      error: (error, _) =>
                          const Text('Could not load your submitted work.'),
                      data: (annotations) => _ReadOnlyCanvas(
                        annotations: annotations,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Text('Score / 100', style: AppTextStyles.title),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  assignment.finalScore == null
                      ? 'Not graded yet'
                      : '${assignment.finalScore}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: assignment.finalScore == null ? 16 : 32,
                    fontWeight: FontWeight.w800,
                    color: assignment.finalScore == null
                        ? AppColors.textSecondary
                        : AppColors.secondary,
                  ),
                ),
              ),
              if (assignment.statusLabel != null) ...[
                const SizedBox(height: 20),
                Text('Mark Status', style: AppTextStyles.title),
                const SizedBox(height: 8),
                StatusPill(
                  label: _statusLabelText(assignment.statusLabel!),
                  background: assignment.statusLabel == GradeStatus.needsRevision
                      ? AppColors.revisionBackground
                      : AppColors.gradedBackground,
                  textColor: assignment.statusLabel == GradeStatus.needsRevision
                      ? AppColors.revisionText
                      : AppColors.gradedText,
                ),
              ],
              const SizedBox(height: 20),
              Text('Feedback from your teacher', style: AppTextStyles.title),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.instructionsBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  assignment.generalFeedback?.isNotEmpty == true
                      ? assignment.generalFeedback!
                      : 'No written feedback yet.',
                  style: AppTextStyles.body,
                ),
              ),
              const SizedBox(height: 24),
              _buildResubmitAction(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResubmitAction(BuildContext context, WidgetRef ref) {
    if (assignment.isPastDue) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'The due date has passed — resubmission is closed.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          final resubmitted = await showDialog<bool>(
            context: context,
            builder: (_) => SubmitAssignmentDialog(assignment: assignment),
          );

          if (resubmitted == true) {
            ref.invalidate(studentAssignmentsProvider);
            if (context.mounted) Navigator.of(context).pop();
          }
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Resubmit'),
      ),
    );
  }

  String _statusLabelText(GradeStatus status) {
    switch (status) {
      case GradeStatus.excellent:
        return 'Excellent';
      case GradeStatus.satisfactory:
        return 'Satisfactory';
      case GradeStatus.needsRevision:
        return 'Needs Revision';
    }
  }
}

class _ReadOnlyCanvas extends StatelessWidget {
  const _ReadOnlyCanvas({required this.annotations});

  final List<SubmissionAnnotationEntity> annotations;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1400 / 2176,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/assignment.png', fit: BoxFit.cover),
                for (var i = 0; i < annotations.length; i++)
                  _pin(annotations[i], i + 1, size),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pin(SubmissionAnnotationEntity annotation, int number, Size size) {
    return Positioned(
      left: annotation.xPercent / 100 * size.width - 20,
      top: annotation.yPercent / 100 * size.height - 20,
      child: Tooltip(
        message: annotation.text,
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.85),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
