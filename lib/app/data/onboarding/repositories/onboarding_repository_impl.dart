import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/onboarding/datasources/local/onboarding_local_datasource.dart';
import 'package:casppa/app/domain/onboarding/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  ResultFuture<bool> hasCompletedOnboarding() async {
    try {
      final hasCompleted = await _localDataSource.hasCompletedOnboarding();
      return Right(hasCompleted);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultVoid completeOnboarding() async {
    try {
      await _localDataSource.completeOnboarding();
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    }
  }
}
