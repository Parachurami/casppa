import 'package:equatable/equatable.dart';

class AdminOverviewEntity extends Equatable {
  const AdminOverviewEntity({
    required this.subjectCount,
    required this.classCount,
    required this.studentCount,
    required this.teacherCount,
  });

  final int subjectCount;
  final int classCount;
  final int studentCount;
  final int teacherCount;

  @override
  List<Object?> get props => [
    subjectCount,
    classCount,
    studentCount,
    teacherCount,
  ];
}
