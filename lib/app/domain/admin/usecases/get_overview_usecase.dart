import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/admin_overview_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class GetOverviewUseCase extends UseCase<AdminOverviewEntity, NoParams> {
  const GetOverviewUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<AdminOverviewEntity> call(NoParams params) {
    return _repository.getOverview();
  }
}
