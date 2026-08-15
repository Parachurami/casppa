import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/presentation/admin/pages/teacher_detail_page.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class AdminTeachersTab extends ConsumerWidget {
  const AdminTeachersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersState = ref.watch(adminTeachersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Text('Teachers', style: AppTextStyles.heading),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminTeachersProvider);
                  await ref.read(adminTeachersProvider.future);
                },
                child: teachersState.when(
                  loading: () => ShimmerList(
                    itemBuilder: (context, index) => const SkeletonBox(
                      width: double.infinity,
                      height: 76,
                      borderRadius: 14,
                    ),
                  ),
                  error: (error, _) => ListView(
                    children: [
                      const SizedBox(height: 80),
                      AssessmentsEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load teachers',
                        message: 'Check your connection and try again.',
                        ctaLabel: 'Retry',
                        onPressed: () => ref.invalidate(adminTeachersProvider),
                      ),
                    ],
                  ),
                  data: (teachers) {
                    if (teachers.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 80),
                          AssessmentsEmptyState(
                            icon: Icons.school_outlined,
                            title: 'No teachers yet',
                            message: 'Teachers will show up here once they sign up.',
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: teachers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  TeacherDetailPage(teacherId: teacher.id),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    initialsFromName(teacher.name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teacher.name,
                                        style: AppTextStyles.title,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${teacher.classCount} class${teacher.classCount == 1 ? '' : 'es'} · '
                                        '${teacher.assignmentCount} assignments · '
                                        '${teacher.cbtCount} CBTs',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
