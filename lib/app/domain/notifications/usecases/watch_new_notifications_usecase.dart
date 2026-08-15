import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';
import 'package:casppa/app/domain/notifications/repositories/notifications_repository.dart';

class WatchNewNotificationsUseCase extends StreamUseCase<NotificationEntity, String> {
  const WatchNewNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Stream<NotificationEntity> call(String params) {
    return _repository.watchNewNotifications(params);
  }
}
