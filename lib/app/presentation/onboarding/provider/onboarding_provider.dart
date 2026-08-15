import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/di/injection_container.dart';
import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/domain/onboarding/usecases/complete_onboarding_usecase.dart';
import 'package:casppa/app/domain/onboarding/usecases/has_completed_onboarding_usecase.dart';

final hasCompletedOnboardingUseCaseProvider =
    Provider<HasCompletedOnboardingUseCase>((ref) => sl());
final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>(
  (ref) => sl(),
);

class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final result = await ref
        .read(hasCompletedOnboardingUseCaseProvider)
        .call(const NoParams());

    return result.fold((failure) => throw failure, (hasCompleted) => hasCompleted);
  }

  Future<void> complete() async {
    final result = await ref
        .read(completeOnboardingUseCaseProvider)
        .call(const NoParams());

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(true),
    );
  }
}

final onboardingNotifierProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
