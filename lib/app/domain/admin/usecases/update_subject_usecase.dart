import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class UpdateSubjectUseCase
    extends UseCase<void, ({String id, String title})> {
  const UpdateSubjectUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultVoid call(({String id, String title}) params) {
    return _repository.updateSubject(params);
  }
}
