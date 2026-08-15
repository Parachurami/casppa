import 'package:equatable/equatable.dart';

import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';

class StudentAssignmentEntity extends Equatable {
  const StudentAssignmentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.teacherName,
    required this.teacherId,
    required this.dueDate,
    required this.submissionStatus,
    this.submissionId,
    this.bodyText,
    this.finalScore,
    this.statusLabel,
    this.generalFeedback,
  });

  final String id;
  final String title;
  final String? description;
  final String? subject;
  final String teacherName;
  final String teacherId;
  final DateTime? dueDate;
  final StudentSubmissionStatus submissionStatus;

  /// Null when there's no submissions row yet.
  final String? submissionId;

  /// The student's previously submitted answer — used to pre-populate the
  /// resubmit modal.
  final String? bodyText;
  final int? finalScore;
  final GradeStatus? statusLabel;
  final String? generalFeedback;

  bool get isOverdue =>
      submissionStatus == StudentSubmissionStatus.notSubmitted && isPastDue;

  bool get isPastDue => dueDate != null && isPastDueDate(dueDate!);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    subject,
    teacherName,
    teacherId,
    dueDate,
    submissionStatus,
    submissionId,
    bodyText,
    finalScore,
    statusLabel,
    generalFeedback,
  ];
}
