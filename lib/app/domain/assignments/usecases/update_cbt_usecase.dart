import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/params/cbt_input.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class UpdateCbtUseCase extends UseCase<AssignmentEntity, UpdateCbtInput> {
  const UpdateCbtUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<AssignmentEntity> call(UpdateCbtInput params) {
    return _repository.updateCbt(params);
  }
}
