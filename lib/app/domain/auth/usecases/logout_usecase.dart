import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/auth/repositories/auth_repository.dart';

class LogoutUseCase extends UseCase<void, NoParams> {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call(NoParams params) {
    return _repository.logout();
  }
}
