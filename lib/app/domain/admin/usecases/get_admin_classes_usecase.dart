import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class GetAdminClassesUseCase extends UseCase<List<AdminClassEntity>, NoParams> {
  const GetAdminClassesUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<List<AdminClassEntity>> call(NoParams params) {
    return _repository.getClasses();
  }
}
