import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/params/rubric_criterion_input.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

class AssignmentFormSheet extends ConsumerStatefulWidget {
  const AssignmentFormSheet({this.assignment, super.key});

  final AssignmentEntity? assignment;

  @override
  ConsumerState<AssignmentFormSheet> createState() =>
      _AssignmentFormSheetState();
}

class _RubricCriterionForm {
  _RubricCriterionForm({String name = '', String maxPoints = ''})
    : nameController = TextEditingController(text: name),
      pointsController = TextEditingController(text: maxPoints);

  final TextEditingController nameController;
  final TextEditingController pointsController;

  void dispose() {
    nameController.dispose();
    pointsController.dispose();
  }
}

class _AssignmentFormSheetState extends ConsumerState<AssignmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _expectedSubmissionsController;
  late final List<_RubricCriterionForm> _criteria;

  ClassOptionEntity? _selectedClass;
  SubjectOptionEntity? _selectedSubject;
  late DateTime? _dueDate;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    _titleController = TextEditingController(text: assignment?.title ?? '');
    _descriptionController = TextEditingController(
      text: assignment?.description ?? '',
    );
    _expectedSubmissionsController = TextEditingController(
      text: assignment == null ? '' : '${assignment.expectedSubmissions}',
    );
    _dueDate = assignment?.dueDate;
    _criteria = (assignment?.rubricCriteria ?? const [])
        .map(
          (criterion) => _RubricCriterionForm(
            name: criterion.name,
            maxPoints: '${criterion.maxPoints}',
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _expectedSubmissionsController.dispose();
    for (final criterion in _criteria) {
      criterion.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _addCriterion() {
    setState(() => _criteria.add(_RubricCriterionForm()));
  }

  void _removeCriterion(int index) {
    setState(() => _criteria.removeAt(index).dispose());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClass == null || _selectedSubject == null) {
      AppToast.error(context, 'Select a class and subject.');
      return;
    }

    if (_dueDate == null) {
      AppToast.error(context, 'Select a due date.');
      return;
    }

    final expectedSubmissions = int.tryParse(
      _expectedSubmissionsController.text,
    );
    if (expectedSubmissions == null || expectedSubmissions <= 0) {
      AppToast.error(
        context,
        'Enter how many students are expected to submit.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final rubricCriteria = _criteria
        .map(
          (criterion) => RubricCriterionInput(
            name: criterion.nameController.text.trim(),
            maxPoints: int.tryParse(criterion.pointsController.text) ?? 0,
          ),
        )
        .where((criterion) => criterion.name.isNotEmpty)
        .toList();

    final data = CreateAssignmentParams(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      classId: _selectedClass!.id,
      subjectId: _selectedSubject!.id,
      dueDate: _dueDate!,
      expectedSubmissions: expectedSubmissions,
      rubricCriteria: rubricCriteria,
    );

    final notifier = ref.read(teacherAssignmentsProvider.notifier);
    final success = _isEditing
        ? await notifier.updateAssignment(widget.assignment!.id, data)
        : await notifier.createAssignment(data);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      AppToast.success(
        context,
        _isEditing ? 'Assignment updated!' : 'Assignment posted!',
      );
      Navigator.of(context).pop();
    } else {
      AppToast.error(
        context,
        _isEditing
            ? 'Could not save changes.'
            : 'Could not post the assignment.',
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: const Text(
          'This cannot be undone. Students will no longer see this assignment.',
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
        .read(teacherAssignmentsProvider.notifier)
        .deleteAssignment(widget.assignment!.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      AppToast.success(context, 'Assignment deleted.');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Could not delete the assignment.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final classOptions = ref.watch(classOptionsProvider);
    final subjectOptions = ref.watch(subjectOptionsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                Text(
                  _isEditing ? 'Edit Assignment' : 'Create Assignment',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 24),
                Text('Title', style: AppTextStyles.title),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _titleController,
                  label: 'e.g. Algebra Practice Set 4',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a title.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class', style: AppTextStyles.title),
                          const SizedBox(height: 8),
                          classOptions.when(
                            loading: () => const _DropdownSkeleton(),
                            error: (error, _) =>
                                const Text('Could not load classes.'),
                            data: (options) {
                              _selectedClass ??= options
                                  .cast<ClassOptionEntity?>()
                                  .firstWhere(
                                    (option) =>
                                        option?.id ==
                                        widget.assignment?.classId,
                                    orElse: () => null,
                                  );

                              if (options.isEmpty) {
                                return Text(
                                  'No classes yet.',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              }

                              return DropdownButtonFormField<
                                ClassOptionEntity
                              >(
                                initialValue: _selectedClass,
                                isExpanded: true,
                                items: options
                                    .map(
                                      (option) => DropdownMenuItem(
                                        value: option,
                                        child: Text(
                                          option.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedClass = value),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject', style: AppTextStyles.title),
                          const SizedBox(height: 8),
                          subjectOptions.when(
                            loading: () => const _DropdownSkeleton(),
                            error: (error, _) =>
                                const Text('Could not load subjects.'),
                            data: (options) {
                              _selectedSubject ??= options
                                  .cast<SubjectOptionEntity?>()
                                  .firstWhere(
                                    (option) =>
                                        option?.title ==
                                        widget.assignment?.subject,
                                    orElse: () => null,
                                  );

                              if (options.isEmpty) {
                                return Text(
                                  'No subjects yet.',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              }

                              return DropdownButtonFormField<
                                SubjectOptionEntity
                              >(
                                initialValue: _selectedSubject,
                                isExpanded: true,
                                items: options
                                    .map(
                                      (subject) => DropdownMenuItem(
                                        value: subject,
                                        child: Text(
                                          subject.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedSubject = value),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Description / Instructions',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _descriptionController,
                  label: 'What students need to do...',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a description.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Due Date', style: AppTextStyles.title),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dueDate == null
                              ? 'Select a date'
                              : formatShortDate(_dueDate!),
                          style: AppTextStyles.body.copyWith(
                            color: _dueDate == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Expected Submissions', style: AppTextStyles.title),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _expectedSubmissionsController,
                  label: 'e.g. 30',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter how many students are expected to submit.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Rubric Criteria', style: AppTextStyles.title),
                        const SizedBox(width: 6),
                        Text(
                          '(optional)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _addCriterion,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Criterion'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_criteria.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Leave empty to grade on a 0-100 score',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Column(
                    children: List.generate(_criteria.length, (index) {
                      final criterion = _criteria[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: AppTextField(
                                controller: criterion.nameController,
                                label: 'Criterion name',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                controller: criterion.pointsController,
                                label: 'Points',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeCriterion(index),
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    AppToast.info(
                      context,
                      'File attachments are simulated in this build.',
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Attach files (simulated)',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isEditing ? 'Save Changes' : 'Post Assignment',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                if (_isEditing)
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
                          : const Text('Delete Assignment'),
                    ),
                  )
                else
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DropdownSkeleton extends StatelessWidget {
  const _DropdownSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
