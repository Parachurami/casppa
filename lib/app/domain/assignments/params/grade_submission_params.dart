import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/entities/grade_status.dart';

class GradeSubmissionParams extends Equatable {
  const GradeSubmissionParams({
    required this.submissionId,
    required this.finalScore,
    required this.statusLabel,
    required this.generalFeedback,
    required this.returnToStudent,
  });

  final String submissionId;
  final int finalScore;
  final GradeStatus statusLabel;
  final String generalFeedback;

  /// false = "Save & Grade" (kept working, not visible to the student yet).
  /// true = "Return to Student" (status becomes returned, notifies student).
  final bool returnToStudent;

  @override
  List<Object?> get props => [
    submissionId,
    finalScore,
    statusLabel,
    generalFeedback,
    returnToStudent,
  ];
}
