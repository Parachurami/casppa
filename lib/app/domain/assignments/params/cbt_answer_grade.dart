import 'package:equatable/equatable.dart';

class CbtAnswerGrade extends Equatable {
  const CbtAnswerGrade({required this.answerId, required this.awardedPoints});

  final String answerId;
  final int awardedPoints;

  @override
  List<Object?> get props => [answerId, awardedPoints];
}
