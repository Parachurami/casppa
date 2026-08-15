import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/data/auth/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);

  Future<UserModel?> getCachedUser();

  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._authBox);

  static const _tag = 'AuthLocalDataSource';

  final Box<dynamic> _authBox;

  @override
  Future<void> cacheUser(UserModel user) async {
    AppLogger.request(_tag, 'cacheUser', {'id': user.id, 'role': user.role});
    try {
      await _authBox.put(HiveKeys.cachedUser, user);
      AppLogger.response(_tag, 'cacheUser');
    } catch (error) {
      AppLogger.error(_tag, 'cacheUser', error);
      throw CacheException(error.toString());
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    AppLogger.request(_tag, 'getCachedUser');
    try {
      final user = _authBox.get(HiveKeys.cachedUser) as UserModel?;
      AppLogger.response(_tag, 'getCachedUser', user?.id ?? 'null');
      return user;
    } catch (error) {
      AppLogger.error(_tag, 'getCachedUser', error);
      throw CacheException(error.toString());
    }
  }

  @override
  Future<void> clearCachedUser() async {
    AppLogger.request(_tag, 'clearCachedUser');
    try {
      await _authBox.delete(HiveKeys.cachedUser);
      AppLogger.response(_tag, 'clearCachedUser');
    } catch (error) {
      AppLogger.error(_tag, 'clearCachedUser', error);
      throw CacheException(error.toString());
    }
  }
}
