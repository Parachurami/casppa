import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/data/auth/models/user_model.dart';
import 'package:casppa/app/domain/auth/params/auth_login_params.dart';
import 'package:casppa/app/domain/auth/params/auth_sign_up_params.dart';
import 'package:casppa/app/domain/auth/params/update_profile_params.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(AuthLoginParams params);

  Future<UserModel?> signUp(AuthSignUpParams params);

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateProfile(UpdateProfileParams params);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<UserModel> login(AuthLoginParams params) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: params.email,
        password: params.password,
      );

      final authUser = response.user;
      if (authUser == null) {
        throw const AppAuthException('Invalid email or password.');
      }

      return _fetchProfile(authUser);
    } on AuthException catch (error) {
      throw AppAuthException(error.message);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<UserModel?> signUp(AuthSignUpParams params) async {
    try {
      final response = await _client.auth.signUp(
        email: params.email,
        password: params.password,
        data: {
          'full_name': params.fullName,
          'role': params.role.name,
          if (params.classId != null) 'class_id': params.classId,
        },
      );

      final authUser = response.user;
      if (authUser == null) {
        throw const AppAuthException('Could not create your account.');
      }

      if (response.session == null) {
        return null;
      }

      return _fetchProfile(authUser);
    } on AuthException catch (error) {
      throw AppAuthException(error.message);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    try {
      return await _fetchProfile(authUser);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<UserModel> updateProfile(UpdateProfileParams params) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const AppAuthException('You are not signed in.');
    }

    try {
      final row = await _client
          .from('profiles')
          .update({'full_name': params.fullName})
          .eq('id', authUser.id)
          .select()
          .single();

      return UserModel.fromJson({...row, 'email': authUser.email});
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  Future<UserModel> _fetchProfile(User authUser) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .single();

    return UserModel.fromJson({...row, 'email': authUser.email});
  }
}
