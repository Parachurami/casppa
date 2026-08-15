import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/data/assignments/models/assignment_model.dart';
import 'package:casppa/app/data/assignments/models/class_option_model.dart';
import 'package:casppa/app/data/assignments/models/subject_option_model.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/entities/admin_overview_entity.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/admin/entities/teacher_summary_entity.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';

abstract class AdminRemoteDataSource {
  Future<AdminOverviewEntity> getOverview();

  Future<List<SubjectOptionModel>> getSubjects();

  Future<void> createSubject(String title);

  Future<void> updateSubject(({String id, String title}) params);

  Future<void> deleteSubject(String id);

  Future<List<AdminClassEntity>> getClasses();

  Future<AdminClassDetailEntity> getClassDetail(String classId);

  Future<void> createClass(({String name, String? teacherId}) params);

  Future<void> updateClass(
    ({String id, String name, String? teacherId}) params,
  );

  Future<void> deleteClass(String id);

  Future<void> addStudentToClass(({String classId, String studentId}) params);

  Future<void> removeStudentFromClass(
    ({String classId, String studentId}) params,
  );

  Future<List<AssignmentModel>> getAllAssessments();

  Future<List<TeacherSummaryEntity>> getTeachers();

  Future<TeacherDetailEntity> getTeacherDetail(String teacherId);

  Future<List<StudentSummaryEntity>> getStudents();

  Future<StudentDetailEntity> getStudentDetail(String studentId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  const AdminRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<AdminOverviewEntity> getOverview() async {
    try {
      final subjectRows = await _client.from('subjects').select('id');
      final classRows = await _client.from('classes').select('id');
      final studentRows = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'student');
      final teacherRows = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'teacher');

      return AdminOverviewEntity(
        subjectCount: subjectRows.length,
        classCount: classRows.length,
        studentCount: studentRows.length,
        teacherCount: teacherRows.length,
      );
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<SubjectOptionModel>> getSubjects() async {
    try {
      final rows = await _client.from('subjects').select().order('title');
      return rows.map(SubjectOptionModel.fromJson).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> createSubject(String title) async {
    try {
      await _client.from('subjects').insert({'title': title});
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> updateSubject(({String id, String title}) params) async {
    try {
      await _client
          .from('subjects')
          .update({'title': params.title})
          .eq('id', params.id);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteSubject(String id) async {
    try {
      await _client.from('subjects').delete().eq('id', id);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<AdminClassEntity>> getClasses() async {
    try {
      final classRows = await _client
          .from('classes')
          .select('id, name, teacher_id, teacher:profiles!teacher_id(full_name)')
          .order('name');

      final classIds = classRows.map((row) => row['id'] as String).toList();
      final studentCounts = await _classStudentCounts(classIds);

      return classRows.map((row) {
        final teacher = row['teacher'] as Map<String, dynamic>?;
        final id = row['id'] as String;

        return AdminClassEntity(
          id: id,
          name: row['name'] as String,
          teacherId: row['teacher_id'] as String?,
          teacherName: teacher?['full_name'] as String?,
          studentCount: studentCounts[id] ?? 0,
        );
      }).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  Future<Map<String, int>> _classStudentCounts(List<String> classIds) async {
    if (classIds.isEmpty) return {};

    final rows = await _client
        .from('class_students')
        .select('class_id')
        .inFilter('class_id', classIds);

    final counts = <String, int>{};
    for (final row in rows) {
      final id = row['class_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<AdminClassDetailEntity> getClassDetail(String classId) async {
    try {
      final classRow = await _client
          .from('classes')
          .select('id, name, teacher_id, teacher:profiles!teacher_id(full_name)')
          .eq('id', classId)
          .single();

      final studentRows = await _client
          .from('class_students')
          .select('student_id, profiles(id, full_name)')
          .eq('class_id', classId);

      final teacher = classRow['teacher'] as Map<String, dynamic>?;

      final students =
          studentRows.map((row) {
              final profile = row['profiles'] as Map<String, dynamic>?;
              return ClassStudentEntity(
                id: row['student_id'] as String,
                name: profile?['full_name'] as String? ?? 'Unknown',
              );
            }).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      return AdminClassDetailEntity(
        id: classRow['id'] as String,
        name: classRow['name'] as String,
        teacherId: classRow['teacher_id'] as String?,
        teacherName: teacher?['full_name'] as String?,
        students: students,
      );
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> createClass(({String name, String? teacherId}) params) async {
    try {
      await _client.from('classes').insert({
        'name': params.name,
        'teacher_id': params.teacherId,
      });
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> updateClass(
    ({String id, String name, String? teacherId}) params,
  ) async {
    try {
      await _client
          .from('classes')
          .update({'name': params.name, 'teacher_id': params.teacherId})
          .eq('id', params.id);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteClass(String id) async {
    try {
      await _client.from('classes').delete().eq('id', id);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> addStudentToClass(
    ({String classId, String studentId}) params,
  ) async {
    try {
      await _client.from('class_students').insert({
        'class_id': params.classId,
        'student_id': params.studentId,
      });
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> removeStudentFromClass(
    ({String classId, String studentId}) params,
  ) async {
    try {
      await _client
          .from('class_students')
          .delete()
          .eq('class_id', params.classId)
          .eq('student_id', params.studentId);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<AssignmentModel>> getAllAssessments() async {
    try {
      final rows = await _client
          .from('assignments')
          .select('*, class:classes(id, name), subject:subjects(id, title)')
          .order('created_at', ascending: false);

      final assignmentIds = rows.map((row) => row['id'] as String).toList();
      final counts = await _submittedCounts(assignmentIds);

      return rows.map((row) {
        return AssignmentModel.fromJson({
          ...row,
          '_submitted_count': counts[row['id']] ?? 0,
        });
      }).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  Future<Map<String, int>> _submittedCounts(List<String> assignmentIds) async {
    if (assignmentIds.isEmpty) return {};

    final rows = await _client
        .from('submissions')
        .select('assignment_id')
        .inFilter('assignment_id', assignmentIds)
        .eq('is_current', true);

    final counts = <String, int>{};
    for (final row in rows) {
      final id = row['assignment_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<List<TeacherSummaryEntity>> getTeachers() async {
    try {
      final teacherRows = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'teacher')
          .order('full_name');

      final teacherIds = teacherRows.map((row) => row['id'] as String).toList();

      final classRows = teacherIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('classes')
                .select('id, teacher_id')
                .inFilter('teacher_id', teacherIds);

      final assignmentRows = teacherIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('assignments')
                .select('id, type, created_by')
                .inFilter('created_by', teacherIds);

      final classCounts = <String, int>{};
      for (final row in classRows) {
        final id = row['teacher_id'] as String;
        classCounts[id] = (classCounts[id] ?? 0) + 1;
      }

      final assignmentCounts = <String, int>{};
      final cbtCounts = <String, int>{};
      for (final row in assignmentRows) {
        final id = row['created_by'] as String;
        if ((row['type'] as String?) == 'cbt') {
          cbtCounts[id] = (cbtCounts[id] ?? 0) + 1;
        } else {
          assignmentCounts[id] = (assignmentCounts[id] ?? 0) + 1;
        }
      }

      return teacherRows.map((row) {
        final id = row['id'] as String;
        return TeacherSummaryEntity(
          id: id,
          name: row['full_name'] as String? ?? 'Unknown',
          classCount: classCounts[id] ?? 0,
          assignmentCount: assignmentCounts[id] ?? 0,
          cbtCount: cbtCounts[id] ?? 0,
        );
      }).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<TeacherDetailEntity> getTeacherDetail(String teacherId) async {
    try {
      final profileRow = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('id', teacherId)
          .single();

      final classRows = await _client
          .from('classes')
          .select('id, name')
          .eq('teacher_id', teacherId)
          .order('name');

      final assignmentRows = await _client
          .from('assignments')
          .select('id, type')
          .eq('created_by', teacherId);

      var assignmentCount = 0;
      var cbtCount = 0;
      for (final row in assignmentRows) {
        if ((row['type'] as String?) == 'cbt') {
          cbtCount++;
        } else {
          assignmentCount++;
        }
      }

      return TeacherDetailEntity(
        id: profileRow['id'] as String,
        name: profileRow['full_name'] as String? ?? 'Unknown',
        classes: classRows.map(ClassOptionModel.fromJson).toList(),
        assignmentCount: assignmentCount,
        cbtCount: cbtCount,
      );
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<StudentSummaryEntity>> getStudents() async {
    try {
      final studentRows = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'student')
          .order('full_name');

      final studentIds = studentRows.map((row) => row['id'] as String).toList();

      final enrollmentRows = studentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('class_students')
                .select('student_id, classes(name)')
                .inFilter('student_id', studentIds);

      final classNameByStudent = <String, String>{};
      for (final row in enrollmentRows) {
        final cls = row['classes'] as Map<String, dynamic>?;
        if (cls != null) {
          classNameByStudent[row['student_id'] as String] =
              cls['name'] as String;
        }
      }

      final submissionRows = studentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('submissions')
                .select('student_id, final_score')
                .inFilter('student_id', studentIds)
                .eq('is_current', true);

      final scoresByStudent = <String, List<int>>{};
      for (final row in submissionRows) {
        final score = row['final_score'] as num?;
        if (score == null) continue;
        final id = row['student_id'] as String;
        (scoresByStudent[id] ??= []).add(score.toInt());
      }

      return studentRows.map((row) {
        final id = row['id'] as String;
        final scores = scoresByStudent[id];
        final average = (scores == null || scores.isEmpty)
            ? null
            : scores.reduce((a, b) => a + b) / scores.length;

        return StudentSummaryEntity(
          id: id,
          name: row['full_name'] as String? ?? 'Unknown',
          className: classNameByStudent[id],
          averageScore: average,
        );
      }).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<StudentDetailEntity> getStudentDetail(String studentId) async {
    try {
      final profileRow = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('id', studentId)
          .single();

      final enrollmentRows = await _client
          .from('class_students')
          .select('classes(name)')
          .eq('student_id', studentId)
          .limit(1);

      final className = enrollmentRows.isEmpty
          ? null
          : (enrollmentRows.first['classes'] as Map<String, dynamic>?)?['name']
                as String?;

      final submissionRows = await _client
          .from('submissions')
          .select('id, status, final_score, submitted_at, assignments(title, type)')
          .eq('student_id', studentId)
          .eq('is_current', true)
          .order('submitted_at', ascending: false);

      final assessments = submissionRows.map((row) {
        final assignment = row['assignments'] as Map<String, dynamic>?;
        final rawType = assignment?['type'] as String?;
        final rawSubmittedAt = row['submitted_at'] as String?;

        return StudentAssessmentSummaryEntity(
          id: row['id'] as String,
          title: assignment?['title'] as String? ?? 'Untitled',
          type: rawType == null
              ? AssignmentType.assignment
              : AssignmentType.values.byName(rawType),
          status: StudentSubmissionStatus.values.byName(
            row['status'] as String,
          ),
          finalScore: (row['final_score'] as num?)?.toInt(),
          submittedAt: rawSubmittedAt == null
              ? null
              : DateTime.parse(rawSubmittedAt),
        );
      }).toList();

      return StudentDetailEntity(
        id: profileRow['id'] as String,
        name: profileRow['full_name'] as String? ?? 'Unknown',
        className: className,
        assessments: assessments,
      );
    } catch (error) {
      throw ServerException(error.toString());
    }
  }
}
