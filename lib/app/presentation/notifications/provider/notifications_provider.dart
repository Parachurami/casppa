import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/di/injection_container.dart';
import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';
import 'package:casppa/app/domain/notifications/usecases/delete_notification_usecase.dart';
import 'package:casppa/app/domain/notifications/usecases/get_notifications_usecase.dart';
import 'package:casppa/app/domain/notifications/usecases/mark_all_notifications_read_usecase.dart';
import 'package:casppa/app/domain/notifications/usecases/mark_notification_read_usecase.dart';

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>(
  (ref) => sl(),
);
final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) => sl());
final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsReadUseCase>((ref) => sl());
final deleteNotificationUseCaseProvider = Provider<DeleteNotificationUseCase>(
  (ref) => sl(),
);

class NotificationsNotifier extends AsyncNotifier<List<NotificationEntity>> {
  @override
  FutureOr<List<NotificationEntity>> build() async {
    final result = await ref
        .read(getNotificationsUseCaseProvider)
        .call(const NoParams());

    return result.fold(
      (failure) => throw failure,
      (notifications) => notifications,
    );
  }

  Future<void> markAsRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData([
      for (final notification in current)
        notification.id == id
            ? notification.copyWith(isRead: true)
            : notification,
    ]);

    final result = await ref.read(markNotificationReadUseCaseProvider).call(id);
    result.fold((failure) => ref.invalidateSelf(), (_) {});
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData([
      for (final notification in current) notification.copyWith(isRead: true),
    ]);

    final result = await ref
        .read(markAllNotificationsReadUseCaseProvider)
        .call(const NoParams());
    result.fold((failure) => ref.invalidateSelf(), (_) {});
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.where((notification) => notification.id != id).toList(),
    );

    final result = await ref
        .read(deleteNotificationUseCaseProvider)
        .call(id);
    result.fold((failure) => ref.invalidateSelf(), (_) {});
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationEntity>>(
      NotificationsNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull;
  if (notifications == null) return 0;

  return notifications.where((notification) => !notification.isRead).length;
});
