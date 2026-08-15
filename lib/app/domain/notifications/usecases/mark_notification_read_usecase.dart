import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/notifications/repositories/notifications_repository.dart';

class MarkNotificationReadUseCase extends UseCase<void, String> {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  ResultVoid call(String params) {
    return _repository.markAsRead(params);
  }
}
