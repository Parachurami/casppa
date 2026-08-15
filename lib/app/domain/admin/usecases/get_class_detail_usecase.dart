import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class GetClassDetailUseCase extends UseCase<AdminClassDetailEntity, String> {
  const GetClassDetailUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<AdminClassDetailEntity> call(String params) {
    return _repository.getClassDetail(params);
  }
}
