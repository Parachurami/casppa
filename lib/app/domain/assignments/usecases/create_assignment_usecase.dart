import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class CreateAssignmentUseCase
    extends UseCase<AssignmentEntity, CreateAssignmentParams> {
  const CreateAssignmentUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<AssignmentEntity> call(CreateAssignmentParams params) {
    return _repository.createAssignment(params);
  }
}
