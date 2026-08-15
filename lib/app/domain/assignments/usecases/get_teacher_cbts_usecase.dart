import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetTeacherCbtsUseCase extends UseCase<List<AssignmentEntity>, NoParams> {
  const GetTeacherCbtsUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<AssignmentEntity>> call(NoParams params) {
    return _repository.getTeacherCbts();
  }
}
