import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';

class TeacherSummaryEntity extends Equatable {
  const TeacherSummaryEntity({
    required this.id,
    required this.name,
    required this.classCount,
    required this.assignmentCount,
    required this.cbtCount,
  });

  final String id;
  final String name;
  final int classCount;
  final int assignmentCount;
  final int cbtCount;

  @override
  List<Object?> get props => [
    id,
    name,
    classCount,
    assignmentCount,
    cbtCount,
  ];
}

class TeacherDetailEntity extends Equatable {
  const TeacherDetailEntity({
    required this.id,
    required this.name,
    required this.classes,
    required this.assignmentCount,
    required this.cbtCount,
  });

  final String id;
  final String name;
  final List<ClassOptionEntity> classes;
  final int assignmentCount;
  final int cbtCount;

  @override
  List<Object?> get props => [
    id,
    name,
    classes,
    assignmentCount,
    cbtCount,
  ];
}
