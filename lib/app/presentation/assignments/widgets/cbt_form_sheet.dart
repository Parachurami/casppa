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
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/domain/assignments/params/cbt_input.dart';
import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/params/question_draft.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

class CbtFormSheet extends ConsumerStatefulWidget {
  const CbtFormSheet({this.assignment, super.key});

  final AssignmentEntity? assignment;

  @override
  ConsumerState<CbtFormSheet> createState() => _CbtFormSheetState();
}

class _OptionForm {
  _OptionForm({String label = ''})
    : controller = TextEditingController(text: label);

  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _QuestionForm {
  _QuestionForm({this.type = QuestionType.mcq})
    : promptController = TextEditingController(),
      pointsController = TextEditingController(text: '10'),
      modelAnswerController = TextEditingController(),
      options = type == QuestionType.mcq
          ? [_OptionForm(), _OptionForm()]
          : [] {
    correctOptionIndex = 0;
  }

  QuestionType type;
  final TextEditingController promptController;
  final TextEditingController pointsController;
  final TextEditingController modelAnswerController;
  List<_OptionForm> options;
  int correctOptionIndex = 0;
  bool correctBool = true;

  void dispose() {
    promptController.dispose();
    pointsController.dispose();
    modelAnswerController.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _CbtFormSheetState extends ConsumerState<CbtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _expectedSubmissionsController;
  final List<_QuestionForm> _questions = [];

  ClassOptionEntity? _selectedClass;
  SubjectOptionEntity? _selectedSubject;
  DateTime? _dueDate;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _questionsLoaded = false;

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
    if (!_isEditing) {
      _questions.add(_QuestionForm());
      _questionsLoaded = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _expectedSubmissionsController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _loadQuestionsOnce(List<QuestionEntity> questions) {
    if (_questionsLoaded) return;
    _questionsLoaded = true;

    for (final question in questions) {
      final form = _QuestionForm(type: question.type);
      form.promptController.text = question.prompt;
      form.pointsController.text = '${question.points}';
      form.modelAnswerController.text = question.modelAnswer ?? '';
      form.correctBool = question.correctBool ?? true;

      if (question.type == QuestionType.mcq) {
        form.options = question.options
            .map((option) => _OptionForm(label: option.label))
            .toList();
        final correctIndex = question.options.indexWhere(
          (option) => option.isCorrect,
        );
        form.correctOptionIndex = correctIndex < 0 ? 0 : correctIndex;
      }

      _questions.add(form);
    }

    if (_questions.isEmpty) _questions.add(_QuestionForm());
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

  void _addQuestion() {
    setState(() => _questions.add(_QuestionForm()));
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index).dispose());
  }

  void _changeQuestionType(_QuestionForm question, QuestionType type) {
    setState(() {
      question.type = type;
      if (type == QuestionType.mcq && question.options.isEmpty) {
        question.options = [_OptionForm(), _OptionForm()];
      }
    });
  }

  void _addOption(_QuestionForm question) {
    setState(() => question.options.add(_OptionForm()));
  }

  void _removeOption(_QuestionForm question, int index) {
    if (question.options.length <= 2) return;
    setState(() {
      question.options.removeAt(index).dispose();
      if (question.correctOptionIndex >= question.options.length) {
        question.correctOptionIndex = 0;
      }
    });
  }

  List<QuestionDraft>? _buildQuestionDrafts() {
    if (_questions.isEmpty) {
      AppToast.error(context, 'Add at least one question.');
      return null;
    }

    final drafts = <QuestionDraft>[];

    for (final question in _questions) {
      final prompt = question.promptController.text.trim();
      if (prompt.isEmpty) {
        AppToast.error(context, 'Every question needs a prompt.');
        return null;
      }

      final points = int.tryParse(question.pointsController.text);
      if (points == null || points <= 0) {
        AppToast.error(context, 'Enter a valid point value for every question.');
        return null;
      }

      switch (question.type) {
        case QuestionType.mcq:
          final labels = question.options
              .map((option) => option.controller.text.trim())
              .toList();
          if (labels.length < 2 || labels.any((label) => label.isEmpty)) {
            AppToast.error(
              context,
              'Multiple-choice questions need at least 2 filled options.',
            );
            return null;
          }

          drafts.add(
            QuestionDraft(
              type: QuestionType.mcq,
              prompt: prompt,
              points: points,
              options: [
                for (var i = 0; i < labels.length; i++)
                  QuestionOptionDraft(
                    label: labels[i],
                    isCorrect: i == question.correctOptionIndex,
                  ),
              ],
            ),
          );
        case QuestionType.tf:
          drafts.add(
            QuestionDraft(
              type: QuestionType.tf,
              prompt: prompt,
              points: points,
              correctBool: question.correctBool,
            ),
          );
        case QuestionType.shortAnswer:
          final modelAnswer = question.modelAnswerController.text.trim();
          drafts.add(
            QuestionDraft(
              type: QuestionType.shortAnswer,
              prompt: prompt,
              points: points,
              modelAnswer: modelAnswer.isEmpty ? null : modelAnswer,
            ),
          );
      }
    }

    return drafts;
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
        'Enter how many students are expected to take this test.',
      );
      return;
    }

    final questions = _buildQuestionDrafts();
    if (questions == null) return;

    setState(() => _isSubmitting = true);

    final data = CreateAssignmentParams(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      classId: _selectedClass!.id,
      subjectId: _selectedSubject!.id,
      dueDate: _dueDate!,
      expectedSubmissions: expectedSubmissions,
    );

    final notifier = ref.read(teacherCbtsProvider.notifier);
    final success = _isEditing
        ? await notifier.updateCbt(
            UpdateCbtInput(
              id: widget.assignment!.id,
              data: data,
              questions: questions,
            ),
          )
        : await notifier.createCbt(
            CreateCbtInput(data: data, questions: questions),
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      AppToast.success(
        context,
        _isEditing ? 'CBT updated!' : 'CBT posted!',
      );
      Navigator.of(context).pop();
    } else {
      AppToast.error(
        context,
        _isEditing ? 'Could not save changes.' : 'Could not post the CBT.',
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete CBT?'),
        content: const Text(
          'This cannot be undone. Students will no longer see this test.',
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
        .read(teacherCbtsProvider.notifier)
        .deleteCbt(widget.assignment!.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      AppToast.success(context, 'CBT deleted.');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Could not delete the CBT.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final classOptions = ref.watch(classOptionsProvider);
    final subjectOptions = ref.watch(subjectOptionsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_isEditing && !_questionsLoaded) {
      ref.watch(questionsProvider(widget.assignment!.id)).whenData(
        _loadQuestionsOnce,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          if (_isEditing && !_questionsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                Text(
                  _isEditing ? 'Edit CBT' : 'Create CBT',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 24),
                Text('Title', style: AppTextStyles.title),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _titleController,
                  label: 'e.g. Mid-Term Chemistry Quiz',
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
                Text('Instructions', style: AppTextStyles.title),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _descriptionController,
                  label: 'What students should know before starting...',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter instructions.';
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
                Text('Expected Students', style: AppTextStyles.title),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _expectedSubmissionsController,
                  label: 'e.g. 30',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter how many students are expected to take this test.';
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
                    Text('Questions', style: AppTextStyles.title),
                    TextButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Question'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _questions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _QuestionCard(
                      index: i,
                      question: _questions[i],
                      canRemove: _questions.length > 1,
                      onRemove: () => _removeQuestion(i),
                      onTypeChanged: (type) =>
                          _changeQuestionType(_questions[i], type),
                      onAddOption: () => _addOption(_questions[i]),
                      onRemoveOption: (optionIndex) =>
                          _removeOption(_questions[i], optionIndex),
                      onCorrectOptionChanged: (optionIndex) => setState(
                        () => _questions[i].correctOptionIndex = optionIndex,
                      ),
                      onCorrectBoolChanged: (value) =>
                          setState(() => _questions[i].correctBool = value),
                    ),
                  ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: _isEditing ? 'Save Changes' : 'Post CBT',
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
                          : const Text('Delete CBT'),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.canRemove,
    required this.onRemove,
    required this.onTypeChanged,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onCorrectOptionChanged,
    required this.onCorrectBoolChanged,
  });

  final int index;
  final _QuestionForm question;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<QuestionType> onTypeChanged;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final ValueChanged<int> onCorrectOptionChanged;
  final ValueChanged<bool> onCorrectBoolChanged;

  static const _typeLabels = {
    QuestionType.mcq: 'Multiple Choice',
    QuestionType.tf: 'True / False',
    QuestionType.shortAnswer: 'Short Answer',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: AppTextStyles.title,
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuestionType.values.map((type) {
              final isSelected = question.type == type;
              return ChoiceChip(
                label: Text(_typeLabels[type]!),
                selected: isSelected,
                onSelected: (_) => onTypeChanged(type),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: question.promptController,
            label: 'Question prompt',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            child: AppTextField(
              controller: question.pointsController,
              label: 'Points',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 12),
          if (question.type == QuestionType.mcq) ...[
            for (var i = 0; i < question.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => onCorrectOptionChanged(i),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          i == question.correctOptionIndex
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: i == question.correctOptionIndex
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: AppTextField(
                        controller: question.options[i].controller,
                        label: 'Option ${i + 1}',
                      ),
                    ),
                    if (question.options.length > 2)
                      IconButton(
                        onPressed: () => onRemoveOption(i),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: onAddOption,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Option'),
            ),
            Text(
              'Select the radio next to the correct option.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else if (question.type == QuestionType.tf) ...[
            Text('Correct answer', style: AppTextStyles.body),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ToggleOption(
                    label: 'True',
                    isSelected: question.correctBool,
                    onTap: () => onCorrectBoolChanged(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleOption(
                    label: 'False',
                    isSelected: !question.correctBool,
                    onTap: () => onCorrectBoolChanged(false),
                  ),
                ),
              ],
            ),
          ] else ...[
            AppTextField(
              controller: question.modelAnswerController,
              label: 'Model answer (optional, for grading reference)',
              maxLines: 3,
            ),
            const SizedBox(height: 4),
            Text(
              'Held as pending until you manually grade it.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
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
