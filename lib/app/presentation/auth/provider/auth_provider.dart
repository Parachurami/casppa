import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/di/injection_container.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/auth_login_params.dart';
import 'package:casppa/app/domain/auth/params/auth_sign_up_params.dart';
import 'package:casppa/app/domain/auth/params/update_profile_params.dart';
import 'package:casppa/app/domain/auth/usecases/get_current_user_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/login_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/logout_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/sign_up_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/update_profile_usecase.dart';
import 'package:casppa/app/presentation/notifications/provider/notifications_provider.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) => sl());
final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) => sl());
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) => sl());
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>(
  (ref) => sl(),
);
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => sl(),
);

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  FutureOr<UserEntity?> build() async {
    final result = await ref
        .read(getCurrentUserUseCaseProvider)
        .call(const NoParams());

    return result.fold((failure) => throw failure, (user) => user);
  }

  /// Deliberately does not set `state = AsyncLoading()` — LoginPage tracks
  /// its own submitting flag for the button spinner. If this notifier's
  /// state flips to loading mid-submit, `_AuthGate` (which watches the same
  /// provider) swaps LoginPage out for the dashboard skeleton, burying the
  /// button entirely.
  Future<void> login(AuthLoginParams params) async {
    try {
      final result = await ref.read(loginUseCaseProvider).call(params);

      state = result.fold((failure) => AsyncError(failure, StackTrace.current), (
        user,
      ) {
        ref.invalidate(notificationsProvider);
        return AsyncData(user);
      });
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Returns the Either directly (in addition to updating [state]) so the
  /// sign-up page can tell "created and signed in" apart from "created,
  /// awaiting email confirmation" — both would otherwise look identical to
  /// the logged-out AsyncData(null) state.
  Future<Either<Failure, UserEntity?>> signUp(AuthSignUpParams params) async {
    try {
      final result = await ref.read(signUpUseCaseProvider).call(params);

      state = result.fold((failure) => AsyncError(failure, StackTrace.current), (
        user,
      ) {
        if (user != null) ref.invalidate(notificationsProvider);
        return AsyncData(user);
      });

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return Left(ServerFailure(error.toString()));
    }
  }

  Future<void> logout() async {
    try {
      final result = await ref
          .read(logoutUseCaseProvider)
          .call(const NoParams());

      state = result.fold((failure) => AsyncError(failure, StackTrace.current), (
        _,
      ) {
        ref.invalidate(notificationsProvider);
        return const AsyncData(null);
      });
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<Either<Failure, UserEntity>> updateProfile(
    UpdateProfileParams params,
  ) async {
    try {
      final result = await ref
          .read(updateProfileUseCaseProvider)
          .call(params);

      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (user) => AsyncData(user),
      );

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return Left(ServerFailure(error.toString()));
    }
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(
  AuthNotifier.new,
);
