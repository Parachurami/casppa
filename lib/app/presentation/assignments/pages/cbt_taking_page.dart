import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/params/submit_cbt_params.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

class CbtTakingPage extends ConsumerStatefulWidget {
  const CbtTakingPage({required this.assignment, super.key});

  final StudentAssignmentEntity assignment;

  @override
  ConsumerState<CbtTakingPage> createState() => _CbtTakingPageState();
}

class _CbtTakingPageState extends ConsumerState<CbtTakingPage> {
  final Map<String, String> _selectedOptionByQuestion = {};
  final Map<String, bool> _boolAnswerByQuestion = {};
  final Map<String, TextEditingController> _textControllers = {};
  bool _isSubmitting = false;

  TextEditingController _controllerFor(String questionId) {
    return _textControllers.putIfAbsent(
      questionId,
      TextEditingController.new,
    );
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(List<QuestionEntity> questions) async {
    final answers = <CbtAnswerDraft>[];

    for (final question in questions) {
      switch (question.type) {
        case QuestionType.mcq:
          final selected = _selectedOptionByQuestion[question.id];
          if (selected == null) {
            AppToast.error(context, 'Answer every question before submitting.');
            return;
          }
          answers.add(
            CbtAnswerDraft(questionId: question.id, selectedOptionId: selected),
          );
        case QuestionType.tf:
          final selected = _boolAnswerByQuestion[question.id];
          if (selected == null) {
            AppToast.error(context, 'Answer every question before submitting.');
            return;
          }
          answers.add(
            CbtAnswerDraft(questionId: question.id, answerBool: selected),
          );
        case QuestionType.shortAnswer:
          final text = _controllerFor(question.id).text.trim();
          if (text.isEmpty) {
            AppToast.error(context, 'Answer every question before submitting.');
            return;
          }
          answers.add(
            CbtAnswerDraft(questionId: question.id, answerText: text),
          );
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit test?'),
        content: const Text(
          'You cannot change your answers after submitting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(submitCbtAnswersUseCaseProvider)
        .call(
          SubmitCbtParams(assignmentId: widget.assignment.id, answers: answers),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (_) {
        AppToast.success(context, 'Test submitted!');
        ref.invalidate(studentCbtsProvider);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assignment.isPastDue) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.assignment.title)),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'This CBT is overdue and can no longer be submitted.',
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
            ),
          ),
        ),
      );
    }

    final questionsState = ref.watch(
      questionsProvider(widget.assignment.id),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.assignment.title)),
      body: SafeArea(
        child: questionsState.when(
          loading: () => ShimmerList(
            itemBuilder: (context, index) => const SkeletonBox(
              width: double.infinity,
              height: 160,
              borderRadius: 16,
            ),
          ),
          error: (error, _) =>
              const Center(child: Text('Could not load questions.')),
          data: (questions) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.assignment.description?.isNotEmpty == true) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.instructionsBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              widget.assignment.description!,
                              style: AppTextStyles.body,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        for (var i = 0; i < questions.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildQuestion(i, questions[i]),
                          ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: PrimaryButton(
                      label: 'Submit Test',
                      isLoading: _isSubmitting,
                      onPressed: () => _submit(questions),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestion(int index, QuestionEntity question) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Q${index + 1}. ${question.prompt}',
                  style: AppTextStyles.title,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${question.points} pts',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          switch (question.type) {
            QuestionType.mcq => _buildMcqOptions(question),
            QuestionType.tf => _buildTfOptions(question),
            QuestionType.shortAnswer => AppTextField(
              controller: _controllerFor(question.id),
              label: 'Type your answer...',
              maxLines: 4,
            ),
          },
        ],
      ),
    );
  }

  Widget _buildMcqOptions(QuestionEntity question) {
    final selected = _selectedOptionByQuestion[question.id];

    return Column(
      children: question.options.map((option) {
        final isSelected = option.id == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(
              () => _selectedOptionByQuestion[question.id] = option.id,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.tagBackground : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(option.label, style: AppTextStyles.body),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTfOptions(QuestionEntity question) {
    final selected = _boolAnswerByQuestion[question.id];

    return Row(
      children: [
        Expanded(
          child: _tfButton(
            label: 'True',
            isSelected: selected == true,
            onTap: () =>
                setState(() => _boolAnswerByQuestion[question.id] = true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tfButton(
            label: 'False',
            isSelected: selected == false,
            onTap: () =>
                setState(() => _boolAnswerByQuestion[question.id] = false),
          ),
        ),
      ],
    );
  }

  Widget _tfButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
