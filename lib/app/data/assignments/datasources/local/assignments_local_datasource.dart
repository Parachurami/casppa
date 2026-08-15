import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/core/utils/typedefs.dart';

abstract class AssignmentsLocalDataSource {
  Future<void> cacheAssignments(List<DataMap> assignments);

  Future<List<DataMap>> getCachedAssignments();
}

class AssignmentsLocalDataSourceImpl implements AssignmentsLocalDataSource {
  const AssignmentsLocalDataSourceImpl(this._assignmentsBox);

  final Box<dynamic> _assignmentsBox;

  @override
  Future<void> cacheAssignments(List<DataMap> assignments) async {
    try {
      await _assignmentsBox.put(HiveKeys.cachedAssignments, assignments);
    } catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<List<DataMap>> getCachedAssignments() async {
    try {
      final cached = _assignmentsBox.get(HiveKeys.cachedAssignments) as List?;
      if (cached == null) return [];
      return cached.cast<DataMap>();
    } catch (error) {
      throw CacheException(error.toString());
    }
  }
}
