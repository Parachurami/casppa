import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/parent/datasources/remote/parent_remote_datasource.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/parent/repositories/parent_repository.dart';

class ParentRepositoryImpl implements ParentRepository {
  const ParentRepositoryImpl(this._remoteDataSource, this._networkInfo);

  static const _tag = 'ParentRepository';

  final ParentRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<List<StudentSummaryEntity>> getChildren() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getChildren: offline, no cache for this feature');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'getChildren: online, fetching remote');
    try {
      final children = await _remoteDataSource.getChildren();
      AppLogger.state(_tag, 'getChildren: remote returned ${children.length}');
      return Right(children);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getChildren', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<StudentDetailEntity> getChildDetail(String childId) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(
        _tag,
        'getChildDetail($childId): offline, no cache for this feature',
      );
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'getChildDetail($childId): online, fetching remote');
    try {
      final detail = await _remoteDataSource.getChildDetail(childId);
      AppLogger.state(_tag, 'getChildDetail($childId): remote succeeded');
      return Right(detail);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getChildDetail', error);
      return Left(ServerFailure(error.message));
    }
  }
}
