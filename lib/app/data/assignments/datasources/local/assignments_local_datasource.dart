import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/typedefs.dart';

abstract class AssignmentsLocalDataSource {
  Future<void> cacheList(String key, List<DataMap> items);

  Future<List<DataMap>> getCachedList(String key);
}

class AssignmentsLocalDataSourceImpl implements AssignmentsLocalDataSource {
  const AssignmentsLocalDataSourceImpl(this._assignmentsBox);

  final Box<dynamic> _assignmentsBox;

  @override
  Future<void> cacheList(String key, List<DataMap> items) async {
    try {
      await _assignmentsBox.put(key, items);
    } catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<List<DataMap>> getCachedList(String key) async {
    try {
      final cached = _assignmentsBox.get(key) as List?;
      if (cached == null) return [];
      return cached.cast<DataMap>();
    } catch (error) {
      throw CacheException(error.toString());
    }
  }
}
