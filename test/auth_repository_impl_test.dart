import 'package:flutter_test/flutter_test.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/data/auth/datasources/local/auth_local_datasource.dart';
import 'package:casppa/app/data/auth/datasources/remote/auth_remote_datasource.dart';
import 'package:casppa/app/data/auth/models/user_model.dart';
import 'package:casppa/app/data/auth/repositories/auth_repository_impl.dart';
import 'package:casppa/app/domain/auth/params/auth_login_params.dart';
import 'package:casppa/app/domain/auth/params/auth_sign_up_params.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/update_profile_params.dart';

UserModel _user() => UserModel(
  id: 'teacher-1',
  email: 'chioma@casppa.dev',
  name: 'Chioma Okeke',
  roleName: 'teacher',
);

class _StubNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _StubRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(AuthLoginParams params) async => _user();

  @override
  Future<UserModel?> signUp(AuthSignUpParams params) async => _user();

  @override
  Future<UserModel?> getCurrentUser() async => _user();

  @override
  Future<UserModel> updateProfile(UpdateProfileParams params) async => _user();

  @override
  Future<void> logout() async {}
}

/// Every write blows up — the shape of a Hive box that failed to open or ran
/// out of disk.
class _FailingLocalDataSource implements AuthLocalDataSource {
  @override
  Future<void> cacheUser(UserModel user) async {
    throw const CacheException('box is closed');
  }

  @override
  Future<UserModel?> getCachedUser() async => null;

  @override
  Future<void> clearCachedUser() async {}
}

void main() {
  late AuthRepositoryImpl repository;

  setUp(() {
    repository = AuthRepositoryImpl(
      _StubRemoteDataSource(),
      _FailingLocalDataSource(),
      _StubNetworkInfo(),
    );
  });

  test('login succeeds even when the offline cache write fails', () async {
    final result = await repository.login(
      const AuthLoginParams(email: 'chioma@casppa.dev', password: 'hunter2'),
    );

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()?.id, 'teacher-1');
  });

  test('signUp succeeds even when the offline cache write fails', () async {
    final result = await repository.signUp(
      const AuthSignUpParams(
        email: 'chioma@casppa.dev',
        password: 'hunter2',
        fullName: 'Chioma Okeke',
        role: UserRole.teacher,
      ),
    );

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()?.id, 'teacher-1');
  });

  test(
    'getCurrentUser succeeds even when the offline cache write fails',
    () async {
      final result = await repository.getCurrentUser();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()?.id, 'teacher-1');
    },
  );

  test(
    'updateProfile succeeds even when the offline cache write fails',
    () async {
      final result = await repository.updateProfile(
        const UpdateProfileParams(fullName: 'Chioma O.'),
      );

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()?.id, 'teacher-1');
    },
  );
}
