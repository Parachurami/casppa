import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class CreateSubjectUseCase extends UseCase<void, String> {
  const CreateSubjectUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultVoid call(String params) {
    return _repository.createSubject(params);
  }
}
