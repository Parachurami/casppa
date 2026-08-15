import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class TeacherDetailPage extends ConsumerWidget {
  const TeacherDetailPage({required this.teacherId, super.key});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(teacherDetailProvider(teacherId));

    return Scaffold(
      appBar: AppBar(title: Text(detailState.valueOrNull?.name ?? 'Teacher')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherDetailProvider(teacherId));
          await ref.read(teacherDetailProvider(teacherId).future);
        },
        child: detailState.when(
          loading: () => ShimmerList(
            itemBuilder: (context, index) => const SkeletonBox(
              width: double.infinity,
              height: 64,
              borderRadius: 14,
            ),
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 80),
              AssessmentsEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load this teacher',
                message: 'Check your connection and try again.',
                ctaLabel: 'Retry',
                onPressed: () =>
                    ref.invalidate(teacherDetailProvider(teacherId)),
              ),
            ],
          ),
          data: (detail) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Assignments',
                        value: '${detail.assignmentCount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'CBTs',
                        value: '${detail.cbtCount}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'CLASSES (${detail.classes.length})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (detail.classes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No classes assigned yet.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...detail.classes.map(
                    (classOption) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          classOption.name,
                          style: AppTextStyles.body,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
