import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/repositories/auth_repository.dart';

class GetCurrentUserUseCase extends UseCase<UserEntity?, NoParams> {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<UserEntity?> call(NoParams params) {
    return _repository.getCurrentUser();
  }
}
