import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/core/widgets/status_pill.dart';
import 'package:casppa/app/core/widgets/tag_pill.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/presentation/assignments/pages/cbt_grading_page.dart';
import 'package:casppa/app/presentation/assignments/pages/marking_view_page.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/student_submission_tile.dart';

class AssignmentDetailsPage extends ConsumerWidget {
  const AssignmentDetailsPage({
    required this.assignment,
    this.readOnly = false,
    super.key,
  });

  final AssignmentEntity assignment;

  /// Admin oversight mode — hides the roster's grading/marking action.
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsKey = (
      assignmentId: assignment.id,
      classId: assignment.classId,
    );
    final submissionsState = ref.watch(
      assignmentSubmissionsProvider(submissionsKey),
    );
    final isCbt = assignment.type == AssignmentType.cbt;
    final totalPoints = isCbt
        ? ref.watch(questionsProvider(assignment.id)).valueOrNull?.fold<int>(
              0,
              (sum, question) => sum + question.points,
            ) ??
            100
        : 100;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(assignmentSubmissionsProvider(submissionsKey));
            await ref.read(
              assignmentSubmissionsProvider(submissionsKey).future,
            );
          },
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(assignment.title, style: AppTextStyles.heading),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (assignment.className != null)
                    TagPill(label: assignment.className!),
                  if (assignment.subject != null)
                    TagPill(label: assignment.subject!),
                  if (assignment.dueDate != null)
                    StatusPill(
                      label: 'Due ${formatLongDate(assignment.dueDate!)}',
                      background: assignment.isOverdue
                          ? AppColors.statusOverdueBackground
                          : AppColors.tagBackground,
                      textColor: assignment.isOverdue
                          ? AppColors.statusOverdueText
                          : AppColors.tagText,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'INSTRUCTIONS',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.instructionsBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  assignment.description?.isNotEmpty == true
                      ? assignment.description!
                      : 'No instructions provided.',
                  style: AppTextStyles.body,
                ),
              ),
              const SizedBox(height: 24),
              submissionsState.when(
                loading: () => Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ShimmerGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 3; i++)
                          const SubmissionTileSkeleton(),
                      ],
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text('Could not load submissions.\n$error'),
                ),
                data: (submissions) {
                  final submittedCount = submissions
                      .where(
                        (student) =>
                            student.status !=
                            StudentSubmissionStatus.notSubmitted,
                      )
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBMISSIONS ($submittedCount/${submissions.length})',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (submissions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            assignment.classId == null
                                ? 'This assignment has no class assigned.'
                                : 'No students are enrolled in this class yet.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...submissions.map((student) {
                          final markable = submissions
                              .where((s) => s.submissionId != null)
                              .toList();

                          return StudentSubmissionTile(
                            submission: student,
                            totalPoints: totalPoints,
                            readOnly: readOnly,
                            onOpenMarkingView:
                                readOnly || student.submissionId == null
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => isCbt
                                            ? CbtGradingPage(
                                                assignmentTitle:
                                                    assignment.title,
                                                assignmentId: assignment.id,
                                                classId: assignment.classId,
                                                submission: student,
                                              )
                                            : MarkingViewPage(
                                                assignmentTitle:
                                                    assignment.title,
                                                assignmentId: assignment.id,
                                                classId: assignment.classId,
                                                submissions: submissions,
                                                initialIndex: markable
                                                    .indexOf(student),
                                              ),
                                      ),
                                    );
                                  },
                          );
                        }),
                    ],
                  );
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
