import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/notifications/datasources/local/notifications_local_datasource.dart';
import 'package:casppa/app/data/notifications/datasources/remote/notifications_remote_datasource.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';
import 'package:casppa/app/domain/notifications/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  final NotificationsRemoteDataSource _remoteDataSource;
  final NotificationsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<List<NotificationEntity>> getNotifications() async {
    if (await _networkInfo.isConnected) {
      try {
        final notifications = await _remoteDataSource.getNotifications();
        await _localDataSource.cacheNotifications(
          notifications.map(_toCacheJson).toList(),
        );
        return Right(notifications);
      } on ServerException catch (error) {
        return Left(ServerFailure(error.message));
      }
    }

    try {
      final cached = await _localDataSource.getCachedNotifications();
      return Right(cached.map(_fromCacheJson).toList());
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    }
  }

  DataMap _toCacheJson(NotificationEntity notification) {
    return {
      'id': notification.id,
      'type': notification.type,
      'title': notification.title,
      'body': notification.body,
      'assignment_id': notification.assignmentId,
      'submission_id': notification.submissionId,
      'is_read': notification.isRead,
      'created_at': notification.createdAt.toIso8601String(),
    };
  }

  NotificationEntity _fromCacheJson(DataMap json) {
    return NotificationEntity(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      assignmentId: json['assignment_id'] as String?,
      submissionId: json['submission_id'] as String?,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
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

  @override
  Stream<NotificationEntity> watchNewNotifications(String userId) {
    return _remoteDataSource.watchNewNotifications(userId);
  }
}
