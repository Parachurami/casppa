import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(String id);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _currentUserId => _client.auth.currentUser!.id;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);

      return rows.map(_fromRow).toList();
    } catch (error) {
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
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _currentUserId)
          .eq('is_read', false);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _client.from('notifications').delete().eq('id', id);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }
}
