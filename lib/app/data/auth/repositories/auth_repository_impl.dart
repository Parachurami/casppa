import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
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

  static const _tag = 'AuthRepository';

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<UserEntity> login(AuthLoginParams params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'login: offline, cannot authenticate');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'login: online, calling remote');
    try {
      final user = await _remoteDataSource.login(params);
      AppLogger.state(_tag, 'login: succeeded, caching user ${user.id}');
      await _localDataSource.cacheUser(user);
      return Right(user);
    } on AppAuthException catch (error) {
      AppLogger.error(_tag, 'login', error);
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'login', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<UserEntity?> signUp(AuthSignUpParams params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'signUp: offline, cannot sign up');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'signUp: online, calling remote');
    try {
      final user = await _remoteDataSource.signUp(params);
      if (user != null) {
        AppLogger.state(_tag, 'signUp: succeeded, caching user ${user.id}');
        await _localDataSource.cacheUser(user);
      } else {
        AppLogger.state(_tag, 'signUp: succeeded, no session yet (email confirmation pending)');
      }
      return Right(user);
    } on AppAuthException catch (error) {
      AppLogger.error(_tag, 'signUp', error);
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'signUp', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid logout() async {
    try {
      if (await _networkInfo.isConnected) {
        AppLogger.state(_tag, 'logout: online, signing out remote');
        await _remoteDataSource.logout();
      } else {
        AppLogger.state(_tag, 'logout: offline, clearing local session only');
      }
      await _localDataSource.clearCachedUser();
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'logout', error);
      return Left(ServerFailure(error.message));
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'logout', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<UserEntity?> getCurrentUser() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getCurrentUser: online, fetching remote');
      try {
        final user = await _remoteDataSource.getCurrentUser();
        if (user != null) {
          AppLogger.state(_tag, 'getCurrentUser: remote hit, caching ${user.id}');
          await _localDataSource.cacheUser(user);
        } else {
          AppLogger.state(_tag, 'getCurrentUser: no remote session');
        }
        return Right(user);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getCurrentUser', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getCurrentUser: offline, reading cache');
    try {
      final UserModel? cachedUser = await _localDataSource.getCachedUser();
      return Right(cachedUser);
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getCurrentUser', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<UserEntity> updateProfile(UpdateProfileParams params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'updateProfile: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'updateProfile: online, calling remote');
    try {
      final user = await _remoteDataSource.updateProfile(params);
      AppLogger.state(_tag, 'updateProfile: succeeded, caching user ${user.id}');
      await _localDataSource.cacheUser(user);
      return Right(user);
    } on AppAuthException catch (error) {
      AppLogger.error(_tag, 'updateProfile', error);
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'updateProfile', error);
      return Left(ServerFailure(error.message));
    }
  }
}
