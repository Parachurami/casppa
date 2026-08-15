import 'package:equatable/equatable.dart';

class AssignmentSubmissionsParams extends Equatable {
  const AssignmentSubmissionsParams({
    required this.assignmentId,
    required this.classId,
  });

  final String assignmentId;
  final String? classId;

  @override
  List<Object?> get props => [assignmentId, classId];
}
