import 'package:equatable/equatable.dart';

class SubmissionAnswerEntity extends Equatable {
  const SubmissionAnswerEntity({
    required this.id,
    required this.questionId,
    this.selectedOptionId,
    this.answerBool,
    this.answerText,
    this.isCorrect,
    this.awardedPoints,
  });

  final String id;
  final String questionId;
  final String? selectedOptionId;
  final bool? answerBool;
  final String? answerText;

  /// Null while a short-answer question is still pending manual grading.
  final bool? isCorrect;
  final int? awardedPoints;

  @override
  List<Object?> get props => [
    id,
    questionId,
    selectedOptionId,
    answerBool,
    answerText,
    isCorrect,
    awardedPoints,
  ];
}
