import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class AddStudentToClassUseCase
    extends UseCase<void, ({String classId, String studentId})> {
  const AddStudentToClassUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultVoid call(({String classId, String studentId}) params) {
    return _repository.addStudentToClass(params);
  }
}
