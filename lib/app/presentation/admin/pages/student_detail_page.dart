import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/core/widgets/status_pill.dart';
import 'package:casppa/app/core/widgets/tag_pill.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class StudentDetailPage extends ConsumerWidget {
  const StudentDetailPage({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: Text(detailState.valueOrNull?.name ?? 'Student')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentDetailProvider(studentId));
          await ref.read(studentDetailProvider(studentId).future);
        },
        child: detailState.when(
          loading: () => ShimmerList(
            itemBuilder: (context, index) => const SkeletonBox(
              width: double.infinity,
              height: 76,
              borderRadius: 14,
            ),
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 80),
              AssessmentsEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load this student',
                message: 'Check your connection and try again.',
                ctaLabel: 'Retry',
                onPressed: () =>
                    ref.invalidate(studentDetailProvider(studentId)),
              ),
            ],
          ),
          data: (detail) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                if (detail.className != null)
                  TagPill(label: detail.className!),
                const SizedBox(height: 20),
                Text(
                  'ASSESSMENTS (${detail.assessments.length})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (detail.assessments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No submissions yet.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...detail.assessments.map(
                    (assessment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AssessmentTile(assessment: assessment),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.assessment});

  final StudentAssessmentSummaryEntity assessment;

  @override
  Widget build(BuildContext context) {
    final isGraded = assessment.finalScore != null;
    final isReturned = assessment.status == StudentSubmissionStatus.returned;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assessment.title, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    TagPill(
                      label: assessment.type == AssignmentType.cbt
                          ? 'CBT'
                          : 'Assignment',
                      background: AppColors.pendingBackground,
                      textColor: AppColors.pendingText,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isGraded)
                StatusPill(
                  label: '${assessment.finalScore}',
                  background: AppColors.gradedBackground,
                  textColor: AppColors.gradedText,
                )
              else
                const StatusPill(
                  label: 'Ungraded',
                  background: AppColors.pendingBackground,
                  textColor: AppColors.pendingText,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              isReturned ? 'Returned' : 'Submitted',
              if (assessment.submittedAt != null)
                formatShortDate(assessment.submittedAt!),
            ].join(' · '),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
