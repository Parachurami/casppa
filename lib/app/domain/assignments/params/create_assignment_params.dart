import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/params/rubric_criterion_input.dart';

class CreateAssignmentParams extends Equatable {
  const CreateAssignmentParams({
    required this.title,
    required this.description,
    required this.classId,
    required this.subjectId,
    required this.dueDate,
    required this.expectedSubmissions,
    this.rubricCriteria = const [],
  });

  final String title;
  final String description;
  final String classId;
  final String subjectId;
  final DateTime dueDate;
  final int expectedSubmissions;
  final List<RubricCriterionInput> rubricCriteria;

  @override
  List<Object?> get props => [
    title,
    description,
    classId,
    subjectId,
    dueDate,
    expectedSubmissions,
    rubricCriteria,
  ];
}
