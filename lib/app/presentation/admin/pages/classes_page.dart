import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/entities/teacher_summary_entity.dart';
import 'package:casppa/app/presentation/admin/pages/class_detail_page.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class ClassesPage extends ConsumerWidget {
  const ClassesPage({super.key});

  void _openForm(
    BuildContext context,
    WidgetRef ref, {
    AdminClassEntity? adminClass,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClassFormSheet(adminClass: adminClass),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(adminClassesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminClassesProvider);
          await ref.read(adminClassesProvider.future);
        },
        child: classesState.when(
          loading: () => _loadingContent,
          error: (error, _) => classesState.isLoading
              ? _loadingContent
              : ListView(
                  children: [
                    const SizedBox(height: 80),
                    AssessmentsEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load classes',
                      message: 'Check your connection and try again.',
                      ctaLabel: 'Retry',
                      onPressed: () => ref.invalidate(adminClassesProvider),
                    ),
                  ],
                ),
          data: (classes) {
            if (classes.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  AssessmentsEmptyState(
                    icon: Icons.class_outlined,
                    title: 'No classes yet',
                    message: 'Add your first class to get started.',
                    ctaLabel: '+ Add Class',
                    onPressed: () => _openForm(context, ref),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: classes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final adminClass = classes[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ClassDetailPage(classId: adminClass.id),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(adminClass.name, style: AppTextStyles.title),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  adminClass.teacherName ?? 'No teacher assigned',
                                  '${adminClass.studentCount} student${adminClass.studentCount == 1 ? '' : 's'}',
                                ].join(' · '),
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _openForm(context, ref, adminClass: adminClass),
                          icon: const Icon(Icons.edit_outlined, size: 20),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }

  Widget get _loadingContent => ShimmerList(
    itemBuilder: (context, index) => const SkeletonBox(
      width: double.infinity,
      height: 76,
      borderRadius: 14,
    ),
  );
}

class _ClassFormSheet extends ConsumerStatefulWidget {
  const _ClassFormSheet({this.adminClass});

  final AdminClassEntity? adminClass;

  @override
  ConsumerState<_ClassFormSheet> createState() => _ClassFormSheetState();
}

class _ClassFormSheetState extends ConsumerState<_ClassFormSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.adminClass?.name ?? '',
  );
  String? _selectedTeacherId;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.adminClass != null;

  @override
  void initState() {
    super.initState();
    _selectedTeacherId = widget.adminClass?.teacherId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Enter a class name.');
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier = ref.read(adminClassesProvider.notifier);
    final success = _isEditing
        ? await notifier.updateClass(
            id: widget.adminClass!.id,
            name: name,
            teacherId: _selectedTeacherId,
          )
        : await notifier.createClass(name: name, teacherId: _selectedTeacherId);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      AppToast.success(context, _isEditing ? 'Class updated!' : 'Class added!');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Could not save the class.');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete class?'),
        content: const Text(
          'This cannot be undone. Enrolled students will be unenrolled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    final success = await ref
        .read(adminClassesProvider.notifier)
        .deleteClass(widget.adminClass!.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      AppToast.success(context, 'Class deleted.');
      Navigator.of(context).pop();
    } else {
      AppToast.error(
        context,
        'Could not delete this class — it may still have assignments.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final teachersState = ref.watch(adminTeachersProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Class' : 'Add Class',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 20),
            Text('Name', style: AppTextStyles.title),
            const SizedBox(height: 8),
            AppTextField(controller: _nameController, label: 'e.g. Grade 5A'),
            const SizedBox(height: 20),
            Text('Teacher', style: AppTextStyles.title),
            const SizedBox(height: 8),
            teachersState.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => const Text('Could not load teachers.'),
              data: (teachers) {
                final options = <TeacherSummaryEntity?>[null, ...teachers];
                return DropdownButtonFormField<TeacherSummaryEntity?>(
                  initialValue: options.cast<TeacherSummaryEntity?>().firstWhere(
                    (teacher) => teacher?.id == _selectedTeacherId,
                    orElse: () => null,
                  ),
                  isExpanded: true,
                  items: options
                      .map(
                        (teacher) => DropdownMenuItem(
                          value: teacher,
                          child: Text(
                            teacher?.name ?? 'No teacher assigned',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedTeacherId = value?.id),
                );
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isEditing ? 'Save Changes' : 'Add Class',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.statusOverdueBackground,
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isDeleting ? null : _confirmDelete,
                  child: _isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Text('Delete Class'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
