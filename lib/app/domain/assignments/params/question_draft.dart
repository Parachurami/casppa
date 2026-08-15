import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/entities/question_entity.dart';

class QuestionOptionDraft extends Equatable {
  const QuestionOptionDraft({required this.label, required this.isCorrect});

  final String label;
  final bool isCorrect;

  @override
  List<Object?> get props => [label, isCorrect];
}

class QuestionDraft extends Equatable {
  const QuestionDraft({
    required this.type,
    required this.prompt,
    required this.points,
    this.correctBool,
    this.modelAnswer,
    this.options = const [],
  });

  final QuestionType type;
  final String prompt;
  final int points;
  final bool? correctBool;
  final String? modelAnswer;
  final List<QuestionOptionDraft> options;

  @override
  List<Object?> get props => [
    type,
    prompt,
    points,
    correctBool,
    modelAnswer,
    options,
  ];
}
