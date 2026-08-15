import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/notifications/datasources/remote/notifications_remote_datasource.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';
import 'package:casppa/app/domain/notifications/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remoteDataSource, this._networkInfo);

  final NotificationsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<List<NotificationEntity>> getNotifications() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final notifications = await _remoteDataSource.getNotifications();
      return Right(notifications);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid markAsRead(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.markAsRead(id);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid markAllAsRead() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.markAllAsRead();
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteNotification(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.deleteNotification(id);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }
}
