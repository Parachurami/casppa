import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/update_profile_params.dart';
import 'package:casppa/app/domain/auth/repositories/auth_repository.dart';

class UpdateProfileUseCase extends UseCase<UserEntity, UpdateProfileParams> {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<UserEntity> call(UpdateProfileParams params) {
    return _repository.updateProfile(params);
  }
}
