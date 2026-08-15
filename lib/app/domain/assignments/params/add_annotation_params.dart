import 'package:equatable/equatable.dart';

class AddAnnotationParams extends Equatable {
  const AddAnnotationParams({
    required this.submissionId,
    required this.xPercent,
    required this.yPercent,
    required this.text,
  });

  final String submissionId;
  final double xPercent;
  final double yPercent;
  final String text;

  @override
  List<Object?> get props => [submissionId, xPercent, yPercent, text];
}
