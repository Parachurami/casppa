import 'package:equatable/equatable.dart';

class CreateSubmissionParams extends Equatable {
  const CreateSubmissionParams({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.teacherId,
    required this.bodyText,
    this.attachmentFileName,
    this.previousSubmissionId,
  });

  final String assignmentId;
  final String assignmentTitle;
  final String teacherId;
  final String bodyText;

  /// Simulated — no real file storage is wired up yet.
  final String? attachmentFileName;

  /// Set when this call is a resubmission — the prior submission is
  /// superseded and a new versioned row is inserted for re-marking.
  final String? previousSubmissionId;

  @override
  List<Object?> get props => [
    assignmentId,
    assignmentTitle,
    teacherId,
    bodyText,
    attachmentFileName,
    previousSubmissionId,
  ];
}
