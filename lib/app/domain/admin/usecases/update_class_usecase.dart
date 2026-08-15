import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class UpdateClassUseCase
    extends UseCase<void, ({String id, String name, String? teacherId})> {
  const UpdateClassUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultVoid call(({String id, String name, String? teacherId}) params) {
    return _repository.updateClass(params);
  }
}
