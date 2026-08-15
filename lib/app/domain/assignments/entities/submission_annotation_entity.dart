import 'package:equatable/equatable.dart';

class SubmissionAnnotationEntity extends Equatable {
  const SubmissionAnnotationEntity({
    required this.id,
    required this.xPercent,
    required this.yPercent,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final double xPercent;
  final double yPercent;
  final String text;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, xPercent, yPercent, text, createdAt];
}
