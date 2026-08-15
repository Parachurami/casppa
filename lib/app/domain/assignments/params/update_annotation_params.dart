import 'package:equatable/equatable.dart';

class UpdateAnnotationParams extends Equatable {
  const UpdateAnnotationParams({required this.annotationId, required this.text});

  final String annotationId;
  final String text;

  @override
  List<Object?> get props => [annotationId, text];
}
