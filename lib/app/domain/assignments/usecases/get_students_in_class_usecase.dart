import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/student_option_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetStudentsInClassUseCase
    extends UseCase<List<StudentOptionEntity>, String> {
  const GetStudentsInClassUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<StudentOptionEntity>> call(String params) {
    return _repository.getStudentsInClass(params);
  }
}
