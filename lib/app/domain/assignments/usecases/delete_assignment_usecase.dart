import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class DeleteAssignmentUseCase extends UseCase<void, String> {
  const DeleteAssignmentUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultVoid call(String params) {
    return _repository.deleteAssignment(params);
  }
}
