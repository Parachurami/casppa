import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';
import 'package:casppa/app/presentation/notifications/provider/notifications_provider.dart';
import 'package:casppa/app/presentation/notifications/widgets/notification_tile.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final hasUnread = ref.watch(unreadNotificationsCountProvider) > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ref.read(notificationsProvider.future);
        },
        child: notificationsState.when(
          loading: () => _loadingContent,
          error: (error, _) => notificationsState.isLoading
              ? _loadingContent
              : ListView(
                  children: [
                    const SizedBox(height: 80),
                    AssessmentsEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load notifications',
                      message: 'Check your connection and try again.',
                      ctaLabel: 'Retry',
                      onPressed: () => ref.invalidate(notificationsProvider),
                    ),
                  ],
                ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  AssessmentsEmptyState(
                    icon: Icons.notifications_none,
                    title: 'No notifications yet',
                    message: "You're all caught up.",
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              itemCount: notifications.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Dismissible(
                  key: ValueKey(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => ref
                      .read(notificationsProvider.notifier)
                      .delete(notification.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  child: NotificationTile(
                    notification: notification,
                    onTap: notification.isRead
                        ? null
                        : () => ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(notification.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget get _loadingContent => ShimmerList(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
    separatorHeight: 12,
    itemBuilder: (context, index) =>
        const SkeletonBox(width: double.infinity, height: 88, borderRadius: 16),
  );
}
