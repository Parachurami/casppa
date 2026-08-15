import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/core/utils/typedefs.dart';

abstract class NotificationsLocalDataSource {
  Future<void> cacheNotifications(List<DataMap> notifications);

  Future<List<DataMap>> getCachedNotifications();
}

class NotificationsLocalDataSourceImpl implements NotificationsLocalDataSource {
  const NotificationsLocalDataSourceImpl(this._notificationsBox);

  static const _tag = 'NotificationsLocalDataSource';

  final Box<dynamic> _notificationsBox;

  @override
  Future<void> cacheNotifications(List<DataMap> notifications) async {
    AppLogger.request(_tag, 'cacheNotifications', {
      'count': notifications.length,
    });
    try {
      await _notificationsBox.put(HiveKeys.cachedNotifications, notifications);
      AppLogger.response(_tag, 'cacheNotifications');
    } catch (error) {
      AppLogger.error(_tag, 'cacheNotifications', error);
      throw CacheException(error.toString());
    }
  }

  @override
  Future<List<DataMap>> getCachedNotifications() async {
    AppLogger.request(_tag, 'getCachedNotifications');
    try {
      final cached =
          _notificationsBox.get(HiveKeys.cachedNotifications) as List?;
      if (cached == null) {
        AppLogger.response(_tag, 'getCachedNotifications', <DataMap>[]);
        return [];
      }
      final result = cached.cast<DataMap>();
      AppLogger.response(_tag, 'getCachedNotifications', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getCachedNotifications', error);
      throw CacheException(error.toString());
    }
  }
}
