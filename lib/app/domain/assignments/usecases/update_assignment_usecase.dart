import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/params/update_assignment_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class UpdateAssignmentUseCase
    extends UseCase<AssignmentEntity, UpdateAssignmentParams> {
  const UpdateAssignmentUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<AssignmentEntity> call(UpdateAssignmentParams params) {
    return _repository.updateAssignment(params.id, params.data);
  }
}
