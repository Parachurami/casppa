import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/entities/grade_status.dart';

enum StudentSubmissionStatus { notSubmitted, submitted, returned, resubmitted }

class StudentSubmissionEntity extends Equatable {
  const StudentSubmissionEntity({
    required this.studentId,
    required this.studentName,
    required this.status,
    this.submissionId,
    this.bodyText,
    this.attachmentFileName,
    this.autoScore,
    this.finalScore,
    this.statusLabel,
    this.generalFeedback,
    this.submittedAt,
  });

  final String studentId;
  final String studentName;
  final StudentSubmissionStatus status;

  /// Null when [status] is [StudentSubmissionStatus.notSubmitted] — there's
  /// no submissions row yet, so nothing to grade or annotate.
  final String? submissionId;
  final String? bodyText;
  final String? attachmentFileName;

  /// CBT only — the sum of auto-graded (MCQ/TF) points, computed on submit.
  final int? autoScore;
  final int? finalScore;
  final GradeStatus? statusLabel;
  final String? generalFeedback;
  final DateTime? submittedAt;

  @override
  List<Object?> get props => [
    studentId,
    studentName,
    status,
    submissionId,
    bodyText,
    attachmentFileName,
    autoScore,
    finalScore,
    statusLabel,
    generalFeedback,
    submittedAt,
  ];
}
