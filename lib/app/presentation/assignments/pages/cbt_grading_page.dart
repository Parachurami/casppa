import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_answer_entity.dart';
import 'package:casppa/app/domain/assignments/params/cbt_answer_grade.dart';
import 'package:casppa/app/domain/assignments/params/grade_submission_params.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/question_answer_review.dart';

class CbtGradingPage extends ConsumerStatefulWidget {
  const CbtGradingPage({
    required this.assignmentTitle,
    required this.assignmentId,
    required this.classId,
    required this.submission,
    super.key,
  });

  final String assignmentTitle;
  final String assignmentId;
  final String? classId;
  final StudentSubmissionEntity submission;

  @override
  ConsumerState<CbtGradingPage> createState() => _CbtGradingPageState();
}

class _CbtGradingPageState extends ConsumerState<CbtGradingPage> {
  late final TextEditingController _feedbackController = TextEditingController(
    text: widget.submission.generalFeedback ?? '',
  );
  final Map<String, int> _pointsByAnswer = {};
  GradeStatus? _statusLabel;
  bool _dataLoaded = false;
  bool _isSavingGrade = false;
  bool _isReturning = false;

  @override
  void initState() {
    super.initState();
    _statusLabel = widget.submission.statusLabel;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _loadOnce(List<QuestionEntity> questions, List<SubmissionAnswerEntity> answers) {
    if (_dataLoaded) return;
    _dataLoaded = true;

    final answersByQuestion = {
      for (final answer in answers) answer.questionId: answer,
    };

    for (final question in questions) {
      if (question.type != QuestionType.shortAnswer) continue;
      final answer = answersByQuestion[question.id];
      if (answer == null) continue;

      _pointsByAnswer[answer.id] = answer.awardedPoints ?? 0;
    }
  }

  int _totalPoints(List<QuestionEntity> questions) =>
      questions.fold(0, (sum, q) => sum + q.points);

  int _liveScore(List<SubmissionAnswerEntity> answers) {
    var total = 0;
    for (final answer in answers) {
      total += _pointsByAnswer[answer.id] ?? answer.awardedPoints ?? 0;
    }
    return total;
  }

  Future<void> _grade({
    required bool returnToStudent,
    required List<QuestionEntity> questions,
    required List<SubmissionAnswerEntity> answers,
  }) async {
    if (_statusLabel == null) {
      AppToast.error(context, 'Select a mark status.');
      return;
    }

    final grades = [
      for (final entry in _pointsByAnswer.entries)
        CbtAnswerGrade(answerId: entry.key, awardedPoints: entry.value),
    ];

    setState(() {
      if (returnToStudent) {
        _isReturning = true;
      } else {
        _isSavingGrade = true;
      }
    });

    if (grades.isNotEmpty) {
      final gradeResult = await ref
          .read(gradeCbtAnswersUseCaseProvider)
          .call(grades);

      final failed = gradeResult.isLeft();
      if (failed) {
        if (!mounted) return;
        setState(() {
          _isSavingGrade = false;
          _isReturning = false;
        });
        AppToast.error(context, 'Could not save short-answer scores.');
        return;
      }
    }

    final finalScore = _liveScore(answers);

    final result = await ref
        .read(gradeSubmissionUseCaseProvider)
        .call(
          GradeSubmissionParams(
            submissionId: widget.submission.submissionId!,
            finalScore: finalScore,
            statusLabel: _statusLabel!,
            generalFeedback: _feedbackController.text.trim(),
            returnToStudent: returnToStudent,
          ),
        );

    if (!mounted) return;
    setState(() {
      _isSavingGrade = false;
      _isReturning = false;
    });

    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(
        context,
        returnToStudent ? 'Returned to student.' : 'Grade saved.',
      );
      ref.invalidate(
        assignmentSubmissionsProvider((
          assignmentId: widget.assignmentId,
          classId: widget.classId,
        )),
      );
      ref.invalidate(
        submissionAnswersProvider(widget.submission.submissionId!),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsState = ref.watch(questionsProvider(widget.assignmentId));
    final answersState = ref.watch(
      submissionAnswersProvider(widget.submission.submissionId!),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.assignmentTitle)),
      body: SafeArea(
        child: questionsState.isLoading || answersState.isLoading
            ? ShimmerList(
                itemBuilder: (context, index) => const SkeletonBox(
                  width: double.infinity,
                  height: 120,
                  borderRadius: 16,
                ),
              )
            : questionsState.hasError || answersState.hasError
            ? const Center(child: Text('Could not load this submission.'))
            : _buildContent(questionsState.value!, answersState.value!),
      ),
    );
  }

  Widget _buildContent(
    List<QuestionEntity> questions,
    List<SubmissionAnswerEntity> answers,
  ) {
    _loadOnce(questions, answers);
    final answersByQuestion = {
      for (final answer in answers) answer.questionId: answer,
    };
    final totalPoints = _totalPoints(questions);
    final liveScore = _liveScore(answers);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.submission.studentName, style: AppTextStyles.heading),
          const SizedBox(height: 20),
          Text('Score', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$liveScore/$totalPoints',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Answers', style: AppTextStyles.title),
          const SizedBox(height: 8),
          for (var i = 0; i < questions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuestionAnswerReview(
                index: i,
                question: questions[i],
                answer: answersByQuestion[questions[i].id],
                gradedPoints: _pointsByAnswer[answersByQuestion[questions[i].id]?.id],
                onGradedPointsChanged:
                    answersByQuestion[questions[i].id] == null
                    ? null
                    : (value) => setState(
                        () => _pointsByAnswer[answersByQuestion[questions[i].id]!.id] =
                            value,
                      ),
              ),
            ),
          const SizedBox(height: 12),
          Text('Mark Status', style: AppTextStyles.title),
          const SizedBox(height: 8),
          _buildMarkStatus(),
          const SizedBox(height: 24),
          Text('General Feedback', style: AppTextStyles.title),
          const SizedBox(height: 8),
          AppTextField(
            controller: _feedbackController,
            label: 'Overall feedback, corrections, suggestions...',
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Save & Grade',
            isLoading: _isSavingGrade,
            onPressed: () => _grade(
              returnToStudent: false,
              questions: questions,
              answers: answers,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isReturning
                  ? null
                  : () => _grade(
                      returnToStudent: true,
                      questions: questions,
                      answers: answers,
                    ),
              icon: _isReturning
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: const Text('Return to Student'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkStatus() {
    final options = [
      (GradeStatus.excellent, 'Excellent', Icons.star_outline),
      (GradeStatus.satisfactory, 'Satisfactory', Icons.check),
      (GradeStatus.needsRevision, 'Needs Revision', Icons.refresh),
    ];

    return Row(
      children: options.map((option) {
        final (status, label, icon) = option;
        final isSelected = _statusLabel == status;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _statusLabel = status),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
