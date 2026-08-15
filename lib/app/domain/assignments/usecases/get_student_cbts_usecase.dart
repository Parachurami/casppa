import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetStudentCbtsUseCase
    extends UseCase<List<StudentAssignmentEntity>, NoParams> {
  const GetStudentCbtsUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<StudentAssignmentEntity>> call(NoParams params) {
    return _repository.getStudentCbts();
  }
}
