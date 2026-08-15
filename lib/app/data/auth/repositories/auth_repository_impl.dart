import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/auth/datasources/local/auth_local_datasource.dart';
import 'package:casppa/app/data/auth/datasources/remote/auth_remote_datasource.dart';
import 'package:casppa/app/data/auth/models/user_model.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/auth_login_params.dart';
import 'package:casppa/app/domain/auth/params/auth_sign_up_params.dart';
import 'package:casppa/app/domain/auth/params/update_profile_params.dart';
import 'package:casppa/app/domain/auth/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<UserEntity> login(AuthLoginParams params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final user = await _remoteDataSource.login(params);
      await _localDataSource.cacheUser(user);
      return Right(user);
    } on AppAuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<UserEntity?> signUp(AuthSignUpParams params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final user = await _remoteDataSource.signUp(params);
      if (user != null) {
        await _localDataSource.cacheUser(user);
      }
      return Right(user);
    } on AppAuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid logout() async {
    try {
      if (await _networkInfo.isConnected) {
        await _remoteDataSource.logout();
      }
      await _localDataSource.clearCachedUser();
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<UserEntity?> getCurrentUser() async {
    if (await _networkInfo.isConnected) {
      try {
        final user = await _remoteDataSource.getCurrentUser();
        if (user != null) {
          await _localDataSource.cacheUser(user);
        }
        return Right(user);
      } on ServerException catch (error) {
        return Left(ServerFailure(error.message));
      }
    }

    try {
      final UserModel? cachedUser = await _localDataSource.getCachedUser();
      return Right(cachedUser);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<UserEntity> updateProfile(UpdateProfileParams params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final user = await _remoteDataSource.updateProfile(params);
      await _localDataSource.cacheUser(user);
      return Right(user);
    } on AppAuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }
}
