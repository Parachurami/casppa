import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/core/utils/typedefs.dart';

abstract class AssignmentsLocalDataSource {
  Future<void> cacheList(String key, List<DataMap> items);

  Future<List<DataMap>> getCachedList(String key);
}

class AssignmentsLocalDataSourceImpl implements AssignmentsLocalDataSource {
  const AssignmentsLocalDataSourceImpl(this._assignmentsBox);

  static const _tag = 'AssignmentsLocalDataSource';

  final Box<dynamic> _assignmentsBox;

  @override
  Future<void> cacheList(String key, List<DataMap> items) async {
    AppLogger.request(_tag, 'cacheList', {'key': key, 'count': items.length});
    try {
      await _assignmentsBox.put(key, items);
      AppLogger.response(_tag, 'cacheList');
    } catch (error) {
      AppLogger.error(_tag, 'cacheList', error);
      throw CacheException(error.toString());
    }
  }

  @override
  Future<List<DataMap>> getCachedList(String key) async {
    AppLogger.request(_tag, 'getCachedList', {'key': key});
    try {
      final cached = _assignmentsBox.get(key) as List?;
      if (cached == null) {
        AppLogger.response(_tag, 'getCachedList', <DataMap>[]);
        return [];
      }
      final result = cached.cast<DataMap>();
      AppLogger.response(_tag, 'getCachedList', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getCachedList', error);
      throw CacheException(error.toString());
    }
  }
}
