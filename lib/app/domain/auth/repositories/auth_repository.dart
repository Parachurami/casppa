import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/auth_login_params.dart';
import 'package:casppa/app/domain/auth/params/auth_sign_up_params.dart';
import 'package:casppa/app/domain/auth/params/update_profile_params.dart';

abstract class AuthRepository {
  ResultFuture<UserEntity> login(AuthLoginParams params);

  /// Returns null when the account was created but needs email
  /// confirmation before a session (and therefore a profile fetch) exists.
  ResultFuture<UserEntity?> signUp(AuthSignUpParams params);

  ResultVoid logout();

  ResultFuture<UserEntity?> getCurrentUser();

  ResultFuture<UserEntity> updateProfile(UpdateProfileParams params);
}
