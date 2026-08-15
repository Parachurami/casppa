import 'package:equatable/equatable.dart';

import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/domain/assignments/entities/rubric_criterion_entity.dart';

enum AssignmentType { assignment, cbt, quickTest }

enum AssignmentStatus { draft, published, closed }

class AssignmentEntity extends Equatable {
  const AssignmentEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.classId,
    required this.className,
    required this.subject,
    required this.dueDate,
    required this.createdBy,
    required this.expectedSubmissions,
    required this.submittedCount,
    this.rubricCriteria = const [],
  });

  final String id;
  final AssignmentType type;
  final AssignmentStatus status;
  final String title;
  final String? description;
  final String? classId;
  final String? className;
  final String? subject;
  final DateTime? dueDate;
  final String createdBy;
  final int expectedSubmissions;
  final int submittedCount;
  final List<RubricCriterionEntity> rubricCriteria;

  bool get isOverdue =>
      status == AssignmentStatus.published &&
      dueDate != null &&
      isPastDueDate(dueDate!);

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    title,
    description,
    classId,
    className,
    subject,
    dueDate,
    createdBy,
    expectedSubmissions,
    submittedCount,
    rubricCriteria,
  ];
}
