import 'package:casppa/app/core/utils/typedefs.dart';

abstract class OnboardingRepository {
  ResultFuture<bool> hasCompletedOnboarding();

  ResultVoid completeOnboarding();
}
