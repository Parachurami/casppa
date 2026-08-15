import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/onboarding/repositories/onboarding_repository.dart';

class CompleteOnboardingUseCase extends UseCase<void, NoParams> {
  const CompleteOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  @override
  ResultVoid call(NoParams params) {
    return _repository.completeOnboarding();
  }
}
