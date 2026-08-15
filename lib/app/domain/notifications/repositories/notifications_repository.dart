import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';

abstract class NotificationsRepository {
  ResultFuture<List<NotificationEntity>> getNotifications();

  ResultVoid markAsRead(String id);

  ResultVoid markAllAsRead();

  ResultVoid deleteNotification(String id);
}
