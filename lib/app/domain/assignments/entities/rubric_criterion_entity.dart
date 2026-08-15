import 'package:equatable/equatable.dart';

class RubricCriterionEntity extends Equatable {
  const RubricCriterionEntity({required this.name, required this.maxPoints});

  final String name;
  final int maxPoints;

  @override
  List<Object?> get props => [name, maxPoints];
}
