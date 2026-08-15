import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/core/utils/typedefs.dart';

abstract class NotificationsLocalDataSource {
  Future<void> cacheNotifications(List<DataMap> notifications);

  Future<List<DataMap>> getCachedNotifications();
}

class NotificationsLocalDataSourceImpl implements NotificationsLocalDataSource {
  const NotificationsLocalDataSourceImpl(this._notificationsBox);

  final Box<dynamic> _notificationsBox;

  @override
  Future<void> cacheNotifications(List<DataMap> notifications) async {
    try {
      await _notificationsBox.put(HiveKeys.cachedNotifications, notifications);
    } catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<List<DataMap>> getCachedNotifications() async {
    try {
      final cached =
          _notificationsBox.get(HiveKeys.cachedNotifications) as List?;
      if (cached == null) return [];
      return cached.cast<DataMap>();
    } catch (error) {
      throw CacheException(error.toString());
    }
  }
}
