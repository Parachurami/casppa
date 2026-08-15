import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/date_formatting.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/params/create_submission_params.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

enum _AttachmentState { idle, loading, uploaded }

class SubmitAssignmentDialog extends ConsumerStatefulWidget {
  const SubmitAssignmentDialog({required this.assignment, super.key});

  final StudentAssignmentEntity assignment;

  @override
  ConsumerState<SubmitAssignmentDialog> createState() =>
      _SubmitAssignmentDialogState();
}

class _SubmitAssignmentDialogState
    extends ConsumerState<SubmitAssignmentDialog> {
  late final _notesController = TextEditingController(
    text: widget.assignment.bodyText ?? '',
  );
  _AttachmentState _attachmentState = _AttachmentState.idle;
  String? _attachmentFileName;
  bool _isSubmitting = false;

  bool get _isResubmit => widget.assignment.submissionId != null;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _simulateAttach() async {
    if (_attachmentState == _AttachmentState.loading) return;

    setState(() => _attachmentState = _AttachmentState.loading);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _attachmentState = _AttachmentState.uploaded;
      _attachmentFileName =
          '${widget.assignment.subject ?? 'Assignment'} - ${widget.assignment.title}.pdf';
    });
    AppToast.success(context, 'File attached.');
  }

  void _removeAttachment() {
    setState(() {
      _attachmentState = _AttachmentState.idle;
      _attachmentFileName = null;
    });
  }

  Future<void> _submit() async {
    if (_isResubmit && widget.assignment.isPastDue) {
      AppToast.error(context, 'The due date has passed — resubmission is closed.');
      return;
    }

    final notes = _notesController.text.trim();
    if (notes.isEmpty && _attachmentState != _AttachmentState.uploaded) {
      AppToast.error(context, 'Add an answer or attach a file first.');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(createSubmissionUseCaseProvider)
        .call(
          CreateSubmissionParams(
            assignmentId: widget.assignment.id,
            assignmentTitle: widget.assignment.title,
            teacherId: widget.assignment.teacherId,
            bodyText: notes,
            attachmentFileName: _attachmentFileName,
            previousSubmissionId: _isResubmit
                ? widget.assignment.submissionId
                : null,
          ),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (_) {
        AppToast.success(
          context,
          _isResubmit ? 'Assignment resubmitted!' : 'Assignment submitted!',
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isResubmit ? 'Resubmit Assignment' : 'Submit Assignment',
                      style: AppTextStyles.heading,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.assignment.title, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (widget.assignment.subject != null)
                          widget.assignment.subject!,
                        if (widget.assignment.dueDate != null)
                          'Due ${formatLongDate(widget.assignment.dueDate!)}',
                      ].join(' · '),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                  onPressed: () => AppToast.info(
                    context,
                    'Downloading is simulated in this build.',
                  ),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download Assignment'),
                ),
              ),
              const SizedBox(height: 20),
              Text('Your answer / notes', style: AppTextStyles.title),
              const SizedBox(height: 8),
              AppTextField(
                controller: _notesController,
                label: 'Type your answer, or describe the work you are attaching...',
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Attach file or photo', style: AppTextStyles.title),
                  const SizedBox(width: 6),
                  Text(
                    '(optional)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildAttachmentArea(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: _isResubmit ? 'Resubmit' : 'Submit',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentArea() {
    switch (_attachmentState) {
      case _AttachmentState.idle:
        return InkWell(
          onTap: _simulateAttach,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.upload_outlined,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Click to attach photo, PDF, or document ',
                        ),
                        TextSpan(
                          text: '(max 5MB)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      case _AttachmentState.loading:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case _AttachmentState.uploaded:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _attachmentFileName ?? 'File attached',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _removeAttachment,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        );
    }
  }
}
