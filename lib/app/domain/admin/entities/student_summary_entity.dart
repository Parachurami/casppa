import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';

class StudentSummaryEntity extends Equatable {
  const StudentSummaryEntity({
    required this.id,
    required this.name,
    required this.className,
    required this.averageScore,
  });

  final String id;
  final String name;
  final String? className;
  final double? averageScore;

  @override
  List<Object?> get props => [id, name, className, averageScore];
}

class StudentAssessmentSummaryEntity extends Equatable {
  const StudentAssessmentSummaryEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.finalScore,
    required this.submittedAt,
  });

  final String id;
  final String title;
  final AssignmentType type;
  final StudentSubmissionStatus status;
  final int? finalScore;
  final DateTime? submittedAt;

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    status,
    finalScore,
    submittedAt,
  ];
}

class StudentDetailEntity extends Equatable {
  const StudentDetailEntity({
    required this.id,
    required this.name,
    required this.className,
    required this.assessments,
  });

  final String id;
  final String name;
  final String? className;
  final List<StudentAssessmentSummaryEntity> assessments;

  @override
  List<Object?> get props => [id, name, className, assessments];
}
