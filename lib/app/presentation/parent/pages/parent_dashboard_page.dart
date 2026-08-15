import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/presentation/auth/pages/profile_page.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/notifications/pages/notifications_page.dart';
import 'package:casppa/app/presentation/notifications/provider/notifications_provider.dart';
import 'package:casppa/app/presentation/parent/pages/child_detail_page.dart';
import 'package:casppa/app/presentation/parent/provider/parent_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final initials = currentUser == null
        ? ''
        : initialsFromName(currentUser.name);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final childrenState = ref.watch(parentChildrenProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(parentChildrenProvider);
            await ref.read(parentChildrenProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Parent', style: AppTextStyles.heading),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const NotificationsPage(),
                              ),
                            ),
                            icon: const Icon(Icons.notifications_none),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                height: 8,
                                width: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfilePage(),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('My Children', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                "A summary of each child's progress",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              childrenState.when(
                loading: () => _childrenLoadingContent,
                error: (error, _) => childrenState.isLoading
                    ? _childrenLoadingContent
                    : AssessmentsEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load your children',
                        message: 'Check your connection and try again.',
                        ctaLabel: 'Retry',
                        onPressed: () =>
                            ref.invalidate(parentChildrenProvider),
                      ),
                data: (children) {
                  if (children.isEmpty) {
                    return const AssessmentsEmptyState(
                      icon: Icons.family_restroom_outlined,
                      title: 'No children linked yet',
                      message:
                          'Children you selected at sign-up will show up here.',
                    );
                  }

                  return Column(
                    children: children
                        .map(
                          (child) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ChildCard(
                              name: child.name,
                              className: child.className,
                              averageScore: child.averageScore,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ChildDetailPage(childId: child.id),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _childrenLoadingContent => ShimmerGroup(
    child: Column(
      children: List.generate(
        3,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonBox(
            width: double.infinity,
            height: 96,
            borderRadius: 16,
          ),
        ),
      ),
    ),
  );
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.name,
    required this.className,
    required this.averageScore,
    required this.onTap,
  });

  final String name;
  final String? className;
  final double? averageScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Text(
                initialsFromName(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.title),
                  const SizedBox(height: 2),
                  Text(
                    className ?? 'No class assigned',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (averageScore != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${averageScore!.round()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    'Avg score',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
