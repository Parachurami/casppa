import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/core/widgets/status_pill.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/question_answer_review.dart';

class CbtResultsPage extends ConsumerWidget {
  const CbtResultsPage({required this.assignment, super.key});

  final StudentAssignmentEntity assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionId = assignment.submissionId;

    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: SafeArea(
        child: submissionId == null
            ? const Center(child: Text('No submission found.'))
            : _ResultsBody(assignment: assignment, submissionId: submissionId),
      ),
    );
  }
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({required this.assignment, required this.submissionId});

  final StudentAssignmentEntity assignment;
  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsState = ref.watch(questionsProvider(assignment.id));
    final answersState = ref.watch(submissionAnswersProvider(submissionId));

    if (questionsState.isLoading || answersState.isLoading) {
      return ShimmerList(
        itemBuilder: (context, index) => const SkeletonBox(
          width: double.infinity,
          height: 120,
          borderRadius: 16,
        ),
      );
    }

    if (questionsState.hasError || answersState.hasError) {
      return const Center(child: Text('Could not load your results.'));
    }

    final questions = questionsState.value!;
    final answers = answersState.value!;
    final answersByQuestion = {
      for (final answer in answers) answer.questionId: answer,
    };

    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);
    final isReturned =
        assignment.submissionStatus == StudentSubmissionStatus.returned;
    final hasPendingGrading = answers.any(
      (answer) => answer.awardedPoints == null,
    );
    final provisionalScore = answers.fold<int>(
      0,
      (sum, answer) => sum + (answer.awardedPoints ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  isReturned
                      ? '${assignment.finalScore}/$totalPoints'
                      : '$provisionalScore/$totalPoints',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                if (!isReturned) ...[
                  const SizedBox(height: 4),
                  Text(
                    hasPendingGrading
                        ? 'Provisional — some answers still need marking'
                        : 'Provisional — awaiting your teacher\'s review',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isReturned && assignment.statusLabel != null) ...[
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
          Text('Your Answers', style: AppTextStyles.title),
          const SizedBox(height: 8),
          for (var i = 0; i < questions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuestionAnswerReview(
                index: i,
                question: questions[i],
                answer: answersByQuestion[questions[i].id],
              ),
            ),
          if (isReturned) ...[
            const SizedBox(height: 12),
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
          ],
        ],
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
