import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/presentation/admin/pages/classes_page.dart';
import 'package:casppa/app/presentation/admin/pages/subjects_page.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/admin/widgets/overview_card.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';
import 'package:casppa/app/presentation/auth/pages/profile_page.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final initials = currentUser == null
        ? ''
        : initialsFromName(currentUser.name);
    final overviewState = ref.watch(adminOverviewProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminOverviewProvider);
            await ref.read(adminOverviewProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Admin', style: AppTextStyles.heading),
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
              const SizedBox(height: 24),
              Text('Overview', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'School-wide snapshot',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              overviewState.when(
                loading: () => ShimmerGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            Expanded(
                              child: SkeletonBox(
                                width: double.infinity,
                                height: 128,
                                borderRadius: 16,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: SkeletonBox(
                                width: double.infinity,
                                height: 128,
                                borderRadius: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            Expanded(
                              child: SkeletonBox(
                                width: double.infinity,
                                height: 128,
                                borderRadius: 16,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: SkeletonBox(
                                width: double.infinity,
                                height: 128,
                                borderRadius: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, _) => AssessmentsEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load overview',
                  message: 'Check your connection and try again.',
                  ctaLabel: 'Retry',
                  onPressed: () => ref.invalidate(adminOverviewProvider),
                ),
                data: (overview) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: OverviewCard(
                              icon: Icons.menu_book_outlined,
                              label: 'Subjects',
                              count: overview.subjectCount,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SubjectsPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OverviewCard(
                              icon: Icons.class_outlined,
                              label: 'Classes',
                              count: overview.classCount,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ClassesPage(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: OverviewCard(
                              icon: Icons.groups_outlined,
                              label: 'Students',
                              count: overview.studentCount,
                              onTap: () => onNavigateToTab(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OverviewCard(
                              icon: Icons.school_outlined,
                              label: 'Teachers',
                              count: overview.teacherCount,
                              onTap: () => onNavigateToTab(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
