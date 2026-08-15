import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/entities/admin_overview_entity.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/admin/entities/teacher_summary_entity.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';

abstract class AdminRepository {
  ResultFuture<AdminOverviewEntity> getOverview();

  ResultFuture<List<SubjectOptionEntity>> getSubjects();

  ResultVoid createSubject(String title);

  ResultVoid updateSubject(({String id, String title}) params);

  ResultVoid deleteSubject(String id);

  ResultFuture<List<AdminClassEntity>> getClasses();

  ResultFuture<AdminClassDetailEntity> getClassDetail(String classId);

  ResultVoid createClass(({String name, String? teacherId}) params);

  ResultVoid updateClass(({String id, String name, String? teacherId}) params);

  ResultVoid deleteClass(String id);

  ResultVoid addStudentToClass(({String classId, String studentId}) params);

  ResultVoid removeStudentFromClass(
    ({String classId, String studentId}) params,
  );

  ResultFuture<List<AssignmentEntity>> getAllAssessments();

  ResultFuture<List<TeacherSummaryEntity>> getTeachers();

  ResultFuture<TeacherDetailEntity> getTeacherDetail(String teacherId);

  ResultFuture<List<StudentSummaryEntity>> getStudents();

  ResultFuture<StudentDetailEntity> getStudentDetail(String studentId);
}
