import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/params/add_annotation_params.dart';
import 'package:casppa/app/domain/assignments/params/grade_submission_params.dart';
import 'package:casppa/app/domain/assignments/params/update_annotation_params.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

enum _Tool { pen, highlight, eraser, comment }

const _quickComments = [
  'Good work!',
  'Well done',
  'See correction above',
  'Revise and resubmit',
  'Check your working',
  'Excellent effort',
];

const _toolColors = [
  Color(0xFFE4574A),
  Color(0xFFF08A6C),
  Color(0xFF2FAE60),
  Color(0xFFF0B860),
  Color(0xFFE47C9A),
];

class MarkingViewPage extends ConsumerStatefulWidget {
  const MarkingViewPage({
    required this.assignmentTitle,
    required this.assignmentId,
    required this.classId,
    required this.submissions,
    required this.initialIndex,
    super.key,
  });

  final String assignmentTitle;
  final String assignmentId;
  final String? classId;
  final List<StudentSubmissionEntity> submissions;
  final int initialIndex;

  @override
  ConsumerState<MarkingViewPage> createState() => _MarkingViewPageState();
}

class _MarkingViewPageState extends ConsumerState<MarkingViewPage> {
  late final List<StudentSubmissionEntity> _markable;
  late int _index;
  late TextEditingController _scoreController;
  late TextEditingController _feedbackController;
  GradeStatus? _statusLabel;
  _Tool _tool = _Tool.comment;
  int _colorIndex = 0;
  Offset? _pendingPinPercent;
  SubmissionAnnotationEntity? _editingAnnotation;
  final _pendingCommentController = TextEditingController();
  bool _isSavingGrade = false;
  bool _isReturning = false;

  StudentSubmissionEntity get _current => _markable[_index];

  @override
  void initState() {
    super.initState();
    _markable = widget.submissions
        .where((s) => s.submissionId != null)
        .toList();
    _index = widget.initialIndex.clamp(0, _markable.length - 1);
    _scoreController = TextEditingController();
    _feedbackController = TextEditingController();
    _loadCurrent();
  }

  void _loadCurrent() {
    _scoreController.text = _current.finalScore?.toString() ?? '';
    _feedbackController.text = _current.generalFeedback ?? '';
    _statusLabel = _current.statusLabel;
    _pendingPinPercent = null;
    _editingAnnotation = null;
    _pendingCommentController.clear();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _markable.length) return;
    setState(() {
      _index = index;
      _loadCurrent();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    _pendingCommentController.dispose();
    super.dispose();
  }

  void _handleCanvasTap(Offset localPosition, Size canvasSize) {
    if (_tool != _Tool.comment) {
      AppToast.info(context, 'Freehand drawing tools are coming soon.');
      return;
    }

    setState(() {
      _editingAnnotation = null;
      _pendingCommentController.clear();
      _pendingPinPercent = Offset(
        (localPosition.dx / canvasSize.width * 100).clamp(0, 100),
        (localPosition.dy / canvasSize.height * 100).clamp(0, 100),
      );
    });
  }

  void _startEditingPin(SubmissionAnnotationEntity annotation) {
    setState(() {
      _editingAnnotation = annotation;
      _pendingPinPercent = Offset(annotation.xPercent, annotation.yPercent);
      _pendingCommentController.text = annotation.text;
    });
  }

  void _dismissPendingComment() {
    setState(() {
      _pendingPinPercent = null;
      _editingAnnotation = null;
      _pendingCommentController.clear();
    });
  }

  Future<void> _savePendingComment() async {
    final text = _pendingCommentController.text.trim();
    final position = _pendingPinPercent;
    if (text.isEmpty || position == null) return;

    final editing = _editingAnnotation;

    final result = editing == null
        ? await ref
              .read(addAnnotationUseCaseProvider)
              .call(
                AddAnnotationParams(
                  submissionId: _current.submissionId!,
                  xPercent: position.dx,
                  yPercent: position.dy,
                  text: text,
                ),
              )
        : await ref
              .read(updateAnnotationUseCaseProvider)
              .call(
                UpdateAnnotationParams(annotationId: editing.id, text: text),
              );

    if (!mounted) return;

    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      _dismissPendingComment();
      ref.invalidate(submissionAnnotationsProvider(_current.submissionId!));
    });
  }

  Future<void> _deleteEditingAnnotation() async {
    final editing = _editingAnnotation;
    if (editing == null) return;

    final result = await ref
        .read(deleteAnnotationUseCaseProvider)
        .call(editing.id);

    if (!mounted) return;

    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      _dismissPendingComment();
      ref.invalidate(submissionAnnotationsProvider(_current.submissionId!));
    });
  }

  Future<void> _grade({required bool returnToStudent}) async {
    final score = int.tryParse(_scoreController.text);
    if (score == null || score < 0 || score > 100) {
      AppToast.error(context, 'Enter a score between 0 and 100.');
      return;
    }
    if (_statusLabel == null) {
      AppToast.error(context, 'Select a mark status.');
      return;
    }

    setState(() {
      if (returnToStudent) {
        _isReturning = true;
      } else {
        _isSavingGrade = true;
      }
    });

    final result = await ref
        .read(gradeSubmissionUseCaseProvider)
        .call(
          GradeSubmissionParams(
            submissionId: _current.submissionId!,
            finalScore: score,
            statusLabel: _statusLabel!,
            generalFeedback: _feedbackController.text.trim(),
            returnToStudent: returnToStudent,
          ),
        );

    if (!mounted) return;
    setState(() {
      _isSavingGrade = false;
      _isReturning = false;
    });

    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(
        context,
        returnToStudent ? 'Returned to student.' : 'Grade saved.',
      );
      ref.invalidate(
        assignmentSubmissionsProvider((
          assignmentId: widget.assignmentId,
          classId: widget.classId,
        )),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final annotationsState = ref.watch(
      submissionAnnotationsProvider(_current.submissionId!),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.assignmentTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentHeader(),
              const SizedBox(height: 16),
              _buildCanvas(annotationsState.valueOrNull ?? const []),
              const SizedBox(height: 20),
              _buildToolbar(),
              const SizedBox(height: 24),
              Text('Score / 100', style: AppTextStyles.title),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _scoreController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 24),
              Text('Mark Status', style: AppTextStyles.title),
              const SizedBox(height: 8),
              _buildMarkStatus(),
              const SizedBox(height: 24),
              Text('General Feedback', style: AppTextStyles.title),
              const SizedBox(height: 8),
              AppTextField(
                controller: _feedbackController,
                label: 'Overall feedback, corrections, suggestions...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Text(
                'Quick comments',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickComments.map((comment) {
                  return ActionChip(
                    label: Text(comment),
                    backgroundColor: AppColors.background,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () {
                      final existing = _feedbackController.text;
                      _feedbackController.text = existing.isEmpty
                          ? comment
                          : '$existing $comment';
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Save & Grade',
                isLoading: _isSavingGrade,
                onPressed: () => _grade(returnToStudent: false),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isReturning
                      ? null
                      : () => _grade(returnToStudent: true),
                  icon: _isReturning
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Return to Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          child: Text(
            initialsFromName(_current.studentName),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_current.studentName, style: AppTextStyles.title),
              Text(
                _current.submittedAt == null
                    ? 'Not submitted'
                    : 'Submitted ${formatShortDate(_current.submittedAt!)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Prev'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_index + 1}/${_markable.length}',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _index < _markable.length - 1
              ? () => _goTo(_index + 1)
              : null,
          icon: const Icon(Icons.arrow_forward, size: 18),
        ),
      ],
    );
  }

  Widget _buildCanvas(List<SubmissionAnnotationEntity> annotations) {
    return AspectRatio(
      aspectRatio: 1400 / 2176,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              key: const Key('markingCanvas'),
              onTapUp: (details) =>
                  _handleCanvasTap(details.localPosition, size),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/assignment.png',
                    fit: BoxFit.cover,
                  ),
                  for (var i = 0; i < annotations.length; i++)
                    _buildPin(annotations[i], i + 1, size),
                  if (_pendingPinPercent != null && _editingAnnotation == null)
                    _buildPendingPin(
                      _pendingPinPercent!,
                      size,
                      annotations.length + 1,
                    ),
                  if (_pendingPinPercent != null)
                    _buildCommentPopup(_pendingPinPercent!, size),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPin(SubmissionAnnotationEntity annotation, int number, Size size) {
    return Positioned(
      left: annotation.xPercent / 100 * size.width - 20,
      top: annotation.yPercent / 100 * size.height - 20,
      child: Tooltip(
        message: annotation.text,
        child: GestureDetector(
          onTap: () => _startEditingPin(annotation),
          child: _numberedPinCircle(number),
        ),
      ),
    );
  }

  Widget _buildPendingPin(Offset percent, Size size, int nextNumber) {
    return Positioned(
      left: percent.dx / 100 * size.width - 20,
      top: percent.dy / 100 * size.height - 20,
      child: _numberedPinCircle(nextNumber),
    );
  }

  Widget _numberedPinCircle(int number) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCommentPopup(Offset percent, Size size) {
    final left = (percent.dx / 100 * size.width - 110).clamp(
      0.0,
      (size.width - 240).clamp(0.0, size.width),
    );
    final top = (percent.dy / 100 * size.height + 16).clamp(
      0.0,
      (size.height - 180).clamp(0.0, size.height),
    );

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.mode_comment_outlined,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _editingAnnotation == null
                          ? 'Add comment'
                          : 'Edit comment',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _dismissPendingComment,
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pendingCommentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Type your comment...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_editingAnnotation != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: _deleteEditingAnnotation,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _dismissPendingComment,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _savePendingComment,
                    child: Text(_editingAnnotation == null ? 'Save' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tool:',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            _toolButton('Pen', Icons.edit_outlined, _Tool.pen),
            const SizedBox(width: 8),
            _toolButton('Highlight', Icons.brush_outlined, _Tool.highlight),
            const SizedBox(width: 8),
            _toolButton('Eraser', Icons.auto_fix_off_outlined, _Tool.eraser),
          ],
        ),
        const SizedBox(height: 8),
        _toolButton('Comment', Icons.push_pin_outlined, _Tool.comment),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Colour:',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < _toolColors.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: _toolColors[i],
                      shape: BoxShape.circle,
                      border: _colorIndex == i
                          ? Border.all(color: AppColors.textPrimary, width: 2)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              height: 16,
              width: 16,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Size:',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Slider(
                value: 0.4,
                onChanged: (_) {},
                activeColor: AppColors.primary,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              label: const Text(
                'Clear',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _toolButton(String label, IconData icon, _Tool tool) {
    final isSelected = _tool == tool;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _tool = tool),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
        foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildMarkStatus() {
    final options = [
      (GradeStatus.excellent, 'excellent', Icons.star_outline),
      (GradeStatus.satisfactory, 'satisfactory', Icons.check),
      (GradeStatus.needsRevision, 'needs revision', Icons.refresh),
    ];

    return Row(
      children: options.map((option) {
        final (status, label, icon) = option;
        final isSelected = _statusLabel == status;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _statusLabel = status),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.tagBackground
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
