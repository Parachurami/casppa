import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/presentation/admin/pages/student_detail_page.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class AdminStudentsTab extends ConsumerWidget {
  const AdminStudentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsState = ref.watch(adminStudentsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Text('Students', style: AppTextStyles.heading),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminStudentsProvider);
                  await ref.read(adminStudentsProvider.future);
                },
                child: studentsState.when(
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
                        title: 'Could not load students',
                        message: 'Check your connection and try again.',
                        ctaLabel: 'Retry',
                        onPressed: () => ref.invalidate(adminStudentsProvider),
                      ),
                    ],
                  ),
                  data: (students) {
                    if (students.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 80),
                          AssessmentsEmptyState(
                            icon: Icons.groups_outlined,
                            title: 'No students yet',
                            message: 'Students will show up here once they sign up.',
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: students.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  StudentDetailPage(studentId: student.id),
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
                                    initialsFromName(student.name),
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
                                        student.name,
                                        style: AppTextStyles.title,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        student.className ?? 'No class assigned',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (student.averageScore != null)
                                  Text(
                                    '${student.averageScore!.round()} avg',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                const SizedBox(width: 4),
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
