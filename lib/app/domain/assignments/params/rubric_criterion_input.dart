import 'package:equatable/equatable.dart';

class RubricCriterionInput extends Equatable {
  const RubricCriterionInput({required this.name, required this.maxPoints});

  final String name;
  final int maxPoints;

  @override
  List<Object?> get props => [name, maxPoints];
}
