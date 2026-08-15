import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/data/auth/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);

  Future<UserModel?> getCachedUser();

  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._authBox);

  final Box<dynamic> _authBox;

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _authBox.put(HiveKeys.cachedUser, user);
    } catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      return _authBox.get(HiveKeys.cachedUser) as UserModel?;
    } catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await _authBox.delete(HiveKeys.cachedUser);
    } catch (error) {
      throw CacheException(error.toString());
    }
  }
}
