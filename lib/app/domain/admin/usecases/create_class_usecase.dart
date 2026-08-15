import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class CreateClassUseCase
    extends UseCase<void, ({String name, String? teacherId})> {
  const CreateClassUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultVoid call(({String name, String? teacherId}) params) {
    return _repository.createClass(params);
  }
}
