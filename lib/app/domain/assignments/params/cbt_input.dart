import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/params/question_draft.dart';

class CreateCbtInput extends Equatable {
  const CreateCbtInput({required this.data, required this.questions});

  final CreateAssignmentParams data;
  final List<QuestionDraft> questions;

  @override
  List<Object?> get props => [data, questions];
}

class UpdateCbtInput extends Equatable {
  const UpdateCbtInput({
    required this.id,
    required this.data,
    required this.questions,
  });

  final String id;
  final CreateAssignmentParams data;
  final List<QuestionDraft> questions;

  @override
  List<Object?> get props => [id, data, questions];
}
