import 'package:equatable/equatable.dart';

class CbtAnswerDraft extends Equatable {
  const CbtAnswerDraft({
    required this.questionId,
    this.selectedOptionId,
    this.answerBool,
    this.answerText,
  });

  final String questionId;
  final String? selectedOptionId;
  final bool? answerBool;
  final String? answerText;

  @override
  List<Object?> get props => [
    questionId,
    selectedOptionId,
    answerBool,
    answerText,
  ];
}

class SubmitCbtParams extends Equatable {
  const SubmitCbtParams({required this.assignmentId, required this.answers});

  final String assignmentId;
  final List<CbtAnswerDraft> answers;

  @override
  List<Object?> get props => [assignmentId, answers];
}
