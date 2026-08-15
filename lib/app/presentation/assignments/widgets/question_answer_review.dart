import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/status_pill.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_answer_entity.dart';

class QuestionAnswerReview extends StatelessWidget {
  const QuestionAnswerReview({
    required this.index,
    required this.question,
    required this.answer,
    this.gradedPoints,
    this.onGradedPointsChanged,
    super.key,
  });

  final int index;
  final QuestionEntity question;
  final SubmissionAnswerEntity? answer;

  /// When [onGradedPointsChanged] is set, short-answer questions render an
  /// editable points slider (teacher grading mode) instead of a read-only
  /// pending/scored pill. [gradedPoints] is the slider's current value.
  final int? gradedPoints;
  final ValueChanged<int>? onGradedPointsChanged;

  bool get _isGradingShortAnswer =>
      onGradedPointsChanged != null && question.type == QuestionType.shortAnswer;

  @override
  Widget build(BuildContext context) {
    final isPending = answer?.awardedPoints == null;
    final isCorrect = answer?.isCorrect == true;

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
              if (_isGradingShortAnswer)
                StatusPill(
                  label: '${gradedPoints ?? 0}/${question.points}',
                  background: AppColors.tagBackground,
                  textColor: AppColors.tagText,
                )
              else if (question.type == QuestionType.shortAnswer && isPending)
                const StatusPill(
                  label: 'Pending',
                  background: AppColors.pendingBackground,
                  textColor: AppColors.pendingText,
                )
              else
                StatusPill(
                  label: '${answer?.awardedPoints ?? 0}/${question.points}',
                  background: isCorrect
                      ? AppColors.gradedBackground
                      : AppColors.revisionBackground,
                  textColor: isCorrect
                      ? AppColors.gradedText
                      : AppColors.revisionText,
                ),
            ],
          ),
          const SizedBox(height: 12),
          switch (question.type) {
            QuestionType.mcq => _buildMcqReview(),
            QuestionType.tf => _buildTfReview(),
            QuestionType.shortAnswer => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                answer?.answerText?.isNotEmpty == true
                    ? answer!.answerText!
                    : 'No answer given.',
                style: AppTextStyles.body,
              ),
            ),
          },
          if (_isGradingShortAnswer) ...[
            const SizedBox(height: 8),
            Text(
              'Score',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: Slider(
                value: (gradedPoints ?? 0).clamp(0, question.points).toDouble(),
                min: 0,
                max: question.points.toDouble(),
                divisions: question.points > 0 ? question.points : null,
                activeColor: AppColors.primary,
                label: '${gradedPoints ?? 0}',
                onChanged: (value) =>
                    onGradedPointsChanged!(value.round()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMcqReview() {
    return Column(
      children: question.options.map((option) {
        final isSelected = option.id == answer?.selectedOptionId;
        final color = option.isCorrect
            ? AppColors.gradedText
            : (isSelected ? AppColors.revisionText : AppColors.textSecondary);
        final background = option.isCorrect
            ? AppColors.gradedBackground
            : (isSelected
                  ? AppColors.revisionBackground
                  : AppColors.background);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  option.isCorrect
                      ? Icons.check_circle
                      : (isSelected ? Icons.cancel : Icons.circle_outlined),
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.label,
                    style: AppTextStyles.body.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTfReview() {
    final selected = answer?.answerBool;
    final correct = question.correctBool;

    return Row(
      children: [
        Expanded(child: _tfTile('True', selected == true, correct == true)),
        const SizedBox(width: 8),
        Expanded(
          child: _tfTile('False', selected == false, correct == false),
        ),
      ],
    );
  }

  Widget _tfTile(String label, bool wasSelected, bool isCorrectAnswer) {
    final color = isCorrectAnswer
        ? AppColors.gradedText
        : (wasSelected ? AppColors.revisionText : AppColors.textSecondary);
    final background = isCorrectAnswer
        ? AppColors.gradedBackground
        : (wasSelected ? AppColors.revisionBackground : AppColors.background);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
