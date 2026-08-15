import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class ClassDetailPage extends ConsumerWidget {
  const ClassDetailPage({required this.classId, super.key});

  final String classId;

  Future<void> _openAddStudentSheet(BuildContext context, WidgetRef ref) async {
    final detail = await ref.read(classDetailProvider(classId).future);
    if (!context.mounted) return;

    final allStudents = await ref.read(adminStudentsProvider.future);
    if (!context.mounted) return;

    final enrolledIds = detail.students.map((s) => s.id).toSet();
    final available = allStudents
        .where((student) => !enrolledIds.contains(student.id))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddStudentSheet(classId: classId, available: available),
    );
  }

  Future<void> _removeStudent(
    BuildContext context,
    WidgetRef ref,
    ClassStudentEntity student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text('${student.name} will be unenrolled from this class.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(removeStudentFromClassUseCaseProvider)
        .call((classId: classId, studentId: student.id));

    if (!context.mounted) return;

    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      ref.invalidate(classDetailProvider(classId));
      ref.invalidate(adminClassesProvider);
      AppToast.success(context, 'Student removed.');
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(classDetailProvider(classId));

    return Scaffold(
      appBar: AppBar(title: Text(detailState.valueOrNull?.name ?? 'Class')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(classDetailProvider(classId));
          await ref.read(classDetailProvider(classId).future);
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
                title: 'Could not load this class',
                message: 'Check your connection and try again.',
                ctaLabel: 'Retry',
                onPressed: () => ref.invalidate(classDetailProvider(classId)),
              ),
            ],
          ),
          data: (detail) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              children: [
                Text(
                  detail.teacherName ?? 'No teacher assigned',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STUDENTS (${detail.students.length})',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAddStudentSheet(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Student'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (detail.students.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No students enrolled yet.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...detail.students.map((student) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                initialsFromName(student.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                student.name,
                                style: AppTextStyles.body,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _removeStudent(context, ref, student),
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddStudentSheet extends ConsumerStatefulWidget {
  const _AddStudentSheet({required this.classId, required this.available});

  final String classId;
  final List<StudentSummaryEntity> available;

  @override
  ConsumerState<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<_AddStudentSheet> {
  final Set<String> _addingIds = {};

  Future<void> _add(StudentSummaryEntity student) async {
    setState(() => _addingIds.add(student.id));

    final result = await ref
        .read(addStudentToClassUseCaseProvider)
        .call((classId: widget.classId, studentId: student.id));

    if (!mounted) return;
    setState(() => _addingIds.remove(student.id));

    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      ref.invalidate(classDetailProvider(widget.classId));
      ref.invalidate(adminClassesProvider);
      AppToast.success(context, '${student.name} added.');
      setState(() => widget.available.remove(student));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Student', style: AppTextStyles.heading),
              const SizedBox(height: 16),
              Expanded(
                child: widget.available.isEmpty
                    ? Center(
                        child: Text(
                          'Every student is already enrolled somewhere else, '
                          'or there are no unassigned students.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: widget.available.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = widget.available[index];
                          final isAdding = _addingIds.contains(student.id);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: AppTextStyles.body,
                                      ),
                                      if (student.className != null)
                                        Text(
                                          'Currently in ${student.className}',
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                isAdding
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: () => _add(student),
                                        child: const Text('Add'),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
