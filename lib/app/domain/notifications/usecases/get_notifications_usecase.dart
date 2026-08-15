import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';
import 'package:casppa/app/domain/notifications/repositories/notifications_repository.dart';

class GetNotificationsUseCase
    extends UseCase<List<NotificationEntity>, NoParams> {
  const GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  ResultFuture<List<NotificationEntity>> call(NoParams params) {
    return _repository.getNotifications();
  }
}
