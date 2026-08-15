import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
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

  static const _tag = 'AuthRemoteDataSource';

  final SupabaseClient _client;

  @override
  Future<UserModel> login(AuthLoginParams params) async {
    // Password intentionally omitted from logs.
    AppLogger.request(_tag, 'login', {'email': params.email});
    try {
      final response = await _client.auth.signInWithPassword(
        email: params.email,
        password: params.password,
      );

      final authUser = response.user;
      if (authUser == null) {
        throw const AppAuthException('Invalid email or password.');
      }

      final user = await _fetchProfile(authUser);
      AppLogger.response(_tag, 'login', user.id);
      return user;
    } on AuthException catch (error) {
      AppLogger.error(_tag, 'login', error);
      throw AppAuthException(error.message);
    } catch (error) {
      AppLogger.error(_tag, 'login', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<UserModel?> signUp(AuthSignUpParams params) async {
    // Password intentionally omitted from logs.
    AppLogger.request(_tag, 'signUp', {
      'email': params.email,
      'role': params.role.name,
      'classId': params.classId,
      'childCount': params.childIds?.length ?? 0,
    });
    try {
      final response = await _client.auth.signUp(
        email: params.email,
        password: params.password,
        data: {
          'full_name': params.fullName,
          'role': params.role.name,
          if (params.classId != null) 'class_id': params.classId,
          if (params.childIds != null && params.childIds!.isNotEmpty)
            'child_ids': jsonEncode(params.childIds),
        },
      );

      final authUser = response.user;
      if (authUser == null) {
        throw const AppAuthException('Could not create your account.');
      }

      if (response.session == null) {
        AppLogger.response(_tag, 'signUp', 'no session (confirmation pending)');
        return null;
      }

      final user = await _fetchProfile(authUser);
      AppLogger.response(_tag, 'signUp', user.id);
      return user;
    } on AuthException catch (error) {
      AppLogger.error(_tag, 'signUp', error);
      throw AppAuthException(error.message);
    } catch (error) {
      AppLogger.error(_tag, 'signUp', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> logout() async {
    AppLogger.request(_tag, 'logout');
    try {
      await _client.auth.signOut();
      AppLogger.response(_tag, 'logout');
    } catch (error) {
      AppLogger.error(_tag, 'logout', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    AppLogger.request(_tag, 'getCurrentUser');
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      AppLogger.response(_tag, 'getCurrentUser', 'no session');
      return null;
    }

    try {
      final user = await _fetchProfile(authUser);
      AppLogger.response(_tag, 'getCurrentUser', user.id);
      return user;
    } catch (error) {
      AppLogger.error(_tag, 'getCurrentUser', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<UserModel> updateProfile(UpdateProfileParams params) async {
    AppLogger.request(_tag, 'updateProfile', {'fullName': params.fullName});
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

      final user = UserModel.fromJson({...row, 'email': authUser.email});
      AppLogger.response(_tag, 'updateProfile', user.id);
      return user;
    } catch (error) {
      AppLogger.error(_tag, 'updateProfile', error);
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
