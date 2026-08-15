import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/notifications/repositories/notifications_repository.dart';

class MarkAllNotificationsReadUseCase extends UseCase<void, NoParams> {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  ResultVoid call(NoParams params) {
    return _repository.markAllAsRead();
  }
}
