import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/presentation/notifications/provider/notifications_provider.dart';
import 'package:casppa/app/presentation/notifications/widgets/graded_notification_toast.dart';

/// Wraps the signed-in dashboard and reacts to new notification rows the
/// instant they're inserted (via Supabase Realtime) — no manual refresh or
/// re-opening the notifications page required. A returned/graded
/// submission gets the themed [showGradedNotificationToast]; anything else
/// gets a plain info toast.
class RealtimeNotificationsGate extends ConsumerWidget {
  const RealtimeNotificationsGate({
    required this.userId,
    required this.child,
    super.key,
  });

  final String userId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(newNotificationsStreamProvider(userId), (previous, next) {
      next.whenData((notification) {
        ref.invalidate(notificationsProvider);

        if (notification.type == 'assignment_returned') {
          showGradedNotificationToast(
            context,
            title: notification.title,
            body: notification.body ?? '',
          );
        } else {
          AppToast.info(context, notification.title);
        }
      });
    });

    return child;
  }
}
