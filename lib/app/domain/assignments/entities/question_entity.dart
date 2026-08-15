import 'package:equatable/equatable.dart';

enum QuestionType { mcq, tf, shortAnswer }

class QuestionOptionEntity extends Equatable {
  const QuestionOptionEntity({
    required this.id,
    required this.label,
    required this.isCorrect,
    required this.position,
  });

  final String id;
  final String label;
  final bool isCorrect;
  final int position;

  @override
  List<Object?> get props => [id, label, isCorrect, position];
}

class QuestionEntity extends Equatable {
  const QuestionEntity({
    required this.id,
    required this.type,
    required this.prompt,
    required this.points,
    required this.position,
    this.correctBool,
    this.modelAnswer,
    this.options = const [],
  });

  final String id;
  final QuestionType type;
  final String prompt;
  final int points;
  final int position;

  /// True/False questions only.
  final bool? correctBool;

  /// Short-answer questions only — a reference answer for the teacher.
  final String? modelAnswer;

  /// MCQ questions only.
  final List<QuestionOptionEntity> options;

  @override
  List<Object?> get props => [
    id,
    type,
    prompt,
    points,
    position,
    correctBool,
    modelAnswer,
    options,
  ];
}
