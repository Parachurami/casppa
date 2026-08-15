import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(String id);

  /// Emits every new notification row inserted for [userId] — e.g. the
  /// moment a teacher returns a graded submission — for as long as the
  /// stream is listened to.
  Stream<NotificationEntity> watchNewNotifications(String userId);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._client);

  static const _tag = 'NotificationsRemoteDataSource';

  final SupabaseClient _client;

  String get _currentUserId => _client.auth.currentUser!.id;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    AppLogger.request(_tag, 'getNotifications', {'userId': _currentUserId});
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);

      final result = rows.map(_fromRow).toList();
      AppLogger.response(_tag, 'getNotifications', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getNotifications', error);
      throw ServerException(error.toString());
    }
  }

  NotificationEntity _fromRow(Map<String, dynamic> row) {
    return NotificationEntity(
      id: row['id'] as String,
      type: row['type'] as String? ?? 'general',
      title: row['title'] as String,
      body: row['body'] as String?,
      assignmentId: row['assignment_id'] as String?,
      submissionId: row['submission_id'] as String?,
      isRead: row['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    AppLogger.request(_tag, 'markAsRead', {'id': id});
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      AppLogger.response(_tag, 'markAsRead');
    } catch (error) {
      AppLogger.error(_tag, 'markAsRead', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> markAllAsRead() async {
    AppLogger.request(_tag, 'markAllAsRead', {'userId': _currentUserId});
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _currentUserId)
          .eq('is_read', false);
      AppLogger.response(_tag, 'markAllAsRead');
    } catch (error) {
      AppLogger.error(_tag, 'markAllAsRead', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    AppLogger.request(_tag, 'deleteNotification', {'id': id});
    try {
      await _client.from('notifications').delete().eq('id', id);
      AppLogger.response(_tag, 'deleteNotification');
    } catch (error) {
      AppLogger.error(_tag, 'deleteNotification', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Stream<NotificationEntity> watchNewNotifications(String userId) {
    AppLogger.request(_tag, 'watchNewNotifications', {'userId': userId});
    final controller = StreamController<NotificationEntity>();

    final channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (controller.isClosed) return;
            final notification = _fromRow(payload.newRecord);
            AppLogger.response(_tag, 'watchNewNotifications', notification.id);
            controller.add(notification);
          },
        )
        .subscribe();

    controller.onCancel = () {
      AppLogger.state(_tag, 'watchNewNotifications: cancelled for $userId');
      unawaited(_client.removeChannel(channel));
    };

    return controller.stream;
  }
}
