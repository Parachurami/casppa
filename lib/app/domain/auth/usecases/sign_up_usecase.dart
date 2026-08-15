import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/auth_sign_up_params.dart';
import 'package:casppa/app/domain/auth/repositories/auth_repository.dart';

class SignUpUseCase extends UseCase<UserEntity?, AuthSignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<UserEntity?> call(AuthSignUpParams params) {
    return _repository.signUp(params);
  }
}
