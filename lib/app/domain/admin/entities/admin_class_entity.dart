import 'package:equatable/equatable.dart';

class AdminClassEntity extends Equatable {
  const AdminClassEntity({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.teacherName,
    required this.studentCount,
  });

  final String id;
  final String name;
  final String? teacherId;
  final String? teacherName;
  final int studentCount;

  @override
  List<Object?> get props => [id, name, teacherId, teacherName, studentCount];
}

class ClassStudentEntity extends Equatable {
  const ClassStudentEntity({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class AdminClassDetailEntity extends Equatable {
  const AdminClassDetailEntity({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.teacherName,
    required this.students,
  });

  final String id;
  final String name;
  final String? teacherId;
  final String? teacherName;
  final List<ClassStudentEntity> students;

  @override
  List<Object?> get props => [id, name, teacherId, teacherName, students];
}
