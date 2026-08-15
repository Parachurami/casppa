import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/onboarding/repositories/onboarding_repository.dart';

class HasCompletedOnboardingUseCase extends UseCase<bool, NoParams> {
  const HasCompletedOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  @override
  ResultFuture<bool> call(NoParams params) {
    return _repository.hasCompletedOnboarding();
  }
}
