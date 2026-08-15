import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';

class SubjectsPage extends ConsumerWidget {
  const SubjectsPage({super.key});

  void _openForm(BuildContext context, WidgetRef ref, {SubjectOptionEntity? subject}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SubjectFormSheet(subject: subject),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsState = ref.watch(adminSubjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminSubjectsProvider);
          await ref.read(adminSubjectsProvider.future);
        },
        child: subjectsState.when(
          loading: () => _loadingContent,
          error: (error, _) => subjectsState.isLoading
              ? _loadingContent
              : ListView(
                  children: [
                    const SizedBox(height: 80),
                    AssessmentsEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load subjects',
                      message: 'Check your connection and try again.',
                      ctaLabel: 'Retry',
                      onPressed: () => ref.invalidate(adminSubjectsProvider),
                    ),
                  ],
                ),
          data: (subjects) {
            if (subjects.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  AssessmentsEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No subjects yet',
                    message: 'Add your first subject to get started.',
                    ctaLabel: '+ Add Subject',
                    onPressed: () => _openForm(context, ref),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: subjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(subject.title, style: AppTextStyles.title),
                      ),
                      IconButton(
                        onPressed: () =>
                            _openForm(context, ref, subject: subject),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    ],
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
        label: const Text('Add Subject'),
      ),
    );
  }

  Widget get _loadingContent => ShimmerList(
    itemBuilder: (context, index) => const SkeletonBox(
      width: double.infinity,
      height: 64,
      borderRadius: 14,
    ),
  );
}

class _SubjectFormSheet extends ConsumerStatefulWidget {
  const _SubjectFormSheet({this.subject});

  final SubjectOptionEntity? subject;

  @override
  ConsumerState<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends ConsumerState<_SubjectFormSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.subject?.title ?? '',
  );
  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.subject != null;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppToast.error(context, 'Enter a subject name.');
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier = ref.read(adminSubjectsProvider.notifier);
    final success = _isEditing
        ? await notifier.updateSubject(widget.subject!.id, title)
        : await notifier.createSubject(title);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      AppToast.success(
        context,
        _isEditing ? 'Subject updated!' : 'Subject added!',
      );
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Could not save the subject.');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete subject?'),
        content: const Text(
          'This cannot be undone. Assignments already using this subject '
          'will keep the reference but may fail to display it correctly.',
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
        .read(adminSubjectsProvider.notifier)
        .deleteSubject(widget.subject!.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      AppToast.success(context, 'Subject deleted.');
      Navigator.of(context).pop();
    } else {
      AppToast.error(
        context,
        'Could not delete this subject — it may still be in use.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Subject' : 'Add Subject',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 20),
            AppTextField(controller: _titleController, label: 'Subject name'),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isEditing ? 'Save Changes' : 'Add Subject',
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
                      : const Text('Delete Subject'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
