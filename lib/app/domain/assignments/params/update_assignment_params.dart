import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';

class UpdateAssignmentParams extends Equatable {
  const UpdateAssignmentParams({required this.id, required this.data});

  final String id;
  final CreateAssignmentParams data;

  @override
  List<Object?> get props => [id, data];
}
