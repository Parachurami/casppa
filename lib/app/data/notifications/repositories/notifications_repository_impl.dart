import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
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

  static const _tag = 'NotificationsRepository';

  final NotificationsRemoteDataSource _remoteDataSource;
  final NotificationsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<List<NotificationEntity>> getNotifications() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getNotifications: online, fetching remote');
      try {
        final notifications = await _remoteDataSource.getNotifications();
        AppLogger.state(
          _tag,
          'getNotifications: remote returned ${notifications.length}, caching',
        );
        await _localDataSource.cacheNotifications(
          notifications.map(_toCacheJson).toList(),
        );
        return Right(notifications);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getNotifications', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getNotifications: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedNotifications();
      return Right(cached.map(_fromCacheJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getNotifications', error);
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
      AppLogger.state(_tag, 'markAsRead($id): offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'markAsRead($id): online, calling remote');
    try {
      await _remoteDataSource.markAsRead(id);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'markAsRead', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid markAllAsRead() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'markAllAsRead: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'markAllAsRead: online, calling remote');
    try {
      await _remoteDataSource.markAllAsRead();
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'markAllAsRead', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteNotification(String id) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'deleteNotification($id): offline, cannot delete');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'deleteNotification($id): online, calling remote');
    try {
      await _remoteDataSource.deleteNotification(id);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'deleteNotification', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  Stream<NotificationEntity> watchNewNotifications(String userId) {
    AppLogger.state(_tag, 'watchNewNotifications: subscribing for $userId');
    return _remoteDataSource.watchNewNotifications(userId);
  }
}
