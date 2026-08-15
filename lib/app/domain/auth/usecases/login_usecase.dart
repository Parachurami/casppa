import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/auth_login_params.dart';
import 'package:casppa/app/domain/auth/repositories/auth_repository.dart';

class LoginUseCase extends UseCase<UserEntity, AuthLoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<UserEntity> call(AuthLoginParams params) {
    return _repository.login(params);
  }
}
