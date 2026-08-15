import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/data/assignments/models/assignment_model.dart';
import 'package:casppa/app/data/assignments/models/class_option_model.dart';
import 'package:casppa/app/data/assignments/models/student_option_model.dart';
import 'package:casppa/app/data/assignments/models/subject_option_model.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_answer_entity.dart';
import 'package:casppa/app/domain/assignments/params/add_annotation_params.dart';
import 'package:casppa/app/domain/assignments/params/cbt_answer_grade.dart';
import 'package:casppa/app/domain/assignments/params/cbt_input.dart';
import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/params/create_submission_params.dart';
import 'package:casppa/app/domain/assignments/params/grade_submission_params.dart';
import 'package:casppa/app/domain/assignments/params/question_draft.dart';
import 'package:casppa/app/domain/assignments/params/submit_cbt_params.dart';

String _gradeStatusToDb(GradeStatus status) {
  switch (status) {
    case GradeStatus.excellent:
      return 'excellent';
    case GradeStatus.satisfactory:
      return 'satisfactory';
    case GradeStatus.needsRevision:
      return 'needs_revision';
  }
}

GradeStatus _gradeStatusFromDb(String value) {
  switch (value) {
    case 'excellent':
      return GradeStatus.excellent;
    case 'satisfactory':
      return GradeStatus.satisfactory;
    case 'needs_revision':
      return GradeStatus.needsRevision;
    default:
      throw ArgumentError('Unknown grade status: $value');
  }
}

String _questionTypeToDb(QuestionType type) {
  switch (type) {
    case QuestionType.mcq:
      return 'mcq';
    case QuestionType.tf:
      return 'tf';
    case QuestionType.shortAnswer:
      return 'short_answer';
  }
}

QuestionType _questionTypeFromDb(String value) {
  switch (value) {
    case 'mcq':
      return QuestionType.mcq;
    case 'tf':
      return QuestionType.tf;
    case 'short_answer':
      return QuestionType.shortAnswer;
    default:
      throw ArgumentError('Unknown question type: $value');
  }
}

const _assignmentSelect = '*, class:classes(id, name), subject:subjects(id, title)';
const _studentAssignmentSelect =
    '*, subject:subjects(title), teacher:profiles!created_by(full_name)';

abstract class AssignmentsRemoteDataSource {
  Future<List<AssignmentModel>> getTeacherAssignments();

  Future<AssignmentModel> createAssignment(CreateAssignmentParams params);

  Future<AssignmentModel> updateAssignment(
    String id,
    CreateAssignmentParams params,
  );

  Future<void> deleteAssignment(String id);

  Future<List<ClassOptionModel>> getClassOptions();

  Future<List<ClassOptionModel>> getAllClassOptions();

  Future<List<SubjectOptionModel>> getSubjectOptions();

  Future<List<StudentOptionModel>> getStudentsInClass(String classId);

  Future<List<StudentSubmissionEntity>> getAssignmentSubmissions({
    required String assignmentId,
    required String? classId,
  });

  Future<List<StudentAssignmentEntity>> getStudentAssignments();

  Future<void> createSubmission(CreateSubmissionParams params);

  Future<List<SubmissionAnnotationEntity>> getSubmissionAnnotations(
    String submissionId,
  );

  Future<SubmissionAnnotationEntity> addAnnotation(
    AddAnnotationParams params,
  );

  Future<void> updateAnnotationText(String annotationId, String text);

  Future<void> deleteAnnotation(String annotationId);

  Future<void> gradeSubmission(GradeSubmissionParams params);

  Future<List<AssignmentModel>> getTeacherCbts();

  Future<List<StudentAssignmentEntity>> getStudentCbts();

  Future<AssignmentModel> createCbt(CreateCbtInput input);

  Future<AssignmentModel> updateCbt(UpdateCbtInput input);

  Future<List<QuestionEntity>> getQuestions(String assignmentId);

  Future<void> submitCbtAnswers(SubmitCbtParams params);

  Future<List<SubmissionAnswerEntity>> getSubmissionAnswers(
    String submissionId,
  );

  Future<void> gradeCbtAnswers(List<CbtAnswerGrade> grades);
}

class AssignmentsRemoteDataSourceImpl implements AssignmentsRemoteDataSource {
  const AssignmentsRemoteDataSourceImpl(this._client);

  static const _tag = 'AssignmentsRemoteDataSource';

  final SupabaseClient _client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppAuthException('You are not signed in.');
    }
    return id;
  }

  @override
  Future<List<AssignmentModel>> getTeacherAssignments() async {
    AppLogger.request(_tag, 'getTeacherAssignments', {
      'teacherId': _currentUserId,
    });
    try {
      final rows = await _client
          .from('assignments')
          .select(_assignmentSelect)
          .eq('created_by', _currentUserId)
          .or('type.is.null,type.eq.assignment')
          .order('created_at', ascending: false);

      final assignmentIds = rows
          .map((row) => row['id'] as String)
          .toList();

      final counts = await _submittedCounts(assignmentIds);

      final result = rows.map((row) {
        return AssignmentModel.fromJson({
          ...row,
          '_submitted_count': counts[row['id']] ?? 0,
        });
      }).toList();
      AppLogger.response(_tag, 'getTeacherAssignments', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getTeacherAssignments', error);
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
  Future<AssignmentModel> createAssignment(
    CreateAssignmentParams params,
  ) async {
    AppLogger.request(_tag, 'createAssignment', {'title': params.title});
    try {
      final row = await _client
          .from('assignments')
          .insert({
            'type': 'assignment',
            'status': 'published',
            'created_by': _currentUserId,
            ..._assignmentPayload(params),
          })
          .select(_assignmentSelect)
          .single();

      final result = AssignmentModel.fromJson({...row, '_submitted_count': 0});
      AppLogger.response(_tag, 'createAssignment', result.id);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'createAssignment', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<AssignmentModel> updateAssignment(
    String id,
    CreateAssignmentParams params,
  ) async {
    AppLogger.request(_tag, 'updateAssignment', {'id': id});
    try {
      final row = await _client
          .from('assignments')
          .update(_assignmentPayload(params))
          .eq('id', id)
          .select(_assignmentSelect)
          .single();

      final counts = await _submittedCounts([id]);

      final result = AssignmentModel.fromJson({
        ...row,
        '_submitted_count': counts[id] ?? 0,
      });
      AppLogger.response(_tag, 'updateAssignment', result.id);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'updateAssignment', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteAssignment(String id) async {
    AppLogger.request(_tag, 'deleteAssignment', {'id': id});
    try {
      // Explicitly cascade the delete — teachers can delete an assignment
      // or CBT even once students have submitted, and that must take every
      // submission (and its answers/annotations) with it, regardless of
      // whether the DB foreign keys are configured with ON DELETE CASCADE.
      final submissionRows = await _client
          .from('submissions')
          .select('id')
          .eq('assignment_id', id);
      final submissionIds = submissionRows
          .map((row) => row['id'] as String)
          .toList();

      if (submissionIds.isNotEmpty) {
        await _client
            .from('submission_answers')
            .delete()
            .inFilter('submission_id', submissionIds);
        await _client
            .from('annotations')
            .delete()
            .inFilter('submission_id', submissionIds);
        await _client
            .from('submissions')
            .delete()
            .inFilter('id', submissionIds);
      }

      final questionRows = await _client
          .from('questions')
          .select('id')
          .eq('assignment_id', id);
      final questionIds = questionRows
          .map((row) => row['id'] as String)
          .toList();

      if (questionIds.isNotEmpty) {
        await _client
            .from('question_options')
            .delete()
            .inFilter('question_id', questionIds);
        await _client.from('questions').delete().eq('assignment_id', id);
      }

      await _client.from('assignments').delete().eq('id', id);
      AppLogger.response(
        _tag,
        'deleteAssignment',
        'deleted ${submissionIds.length} submission(s), '
            '${questionIds.length} question(s)',
      );
    } catch (error) {
      AppLogger.error(_tag, 'deleteAssignment', error);
      throw ServerException(error.toString());
    }
  }

  Map<String, dynamic> _assignmentPayload(CreateAssignmentParams params) {
    return {
      'title': params.title,
      'description': params.description,
      'class_id': params.classId,
      'subject_id': params.subjectId,
      'due_date': params.dueDate.toIso8601String(),
      'expected_submissions': params.expectedSubmissions,
      'rubric_criteria': params.rubricCriteria
          .map((c) => {'name': c.name, 'max_points': c.maxPoints})
          .toList(),
    };
  }

  @override
  Future<List<ClassOptionModel>> getClassOptions() async {
    AppLogger.request(_tag, 'getClassOptions', {'teacherId': _currentUserId});
    try {
      final rows = await _client
          .from('classes')
          .select()
          .eq('teacher_id', _currentUserId)
          .order('name');

      final result = rows.map(ClassOptionModel.fromJson).toList();
      AppLogger.response(_tag, 'getClassOptions', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getClassOptions', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<ClassOptionModel>> getAllClassOptions() async {
    AppLogger.request(_tag, 'getAllClassOptions');
    try {
      final rows = await _client.from('classes').select().order('name');

      final result = rows.map(ClassOptionModel.fromJson).toList();
      AppLogger.response(_tag, 'getAllClassOptions', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getAllClassOptions', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<SubjectOptionModel>> getSubjectOptions() async {
    AppLogger.request(_tag, 'getSubjectOptions');
    try {
      final rows = await _client.from('subjects').select().order('title');

      final result = rows.map(SubjectOptionModel.fromJson).toList();
      AppLogger.response(_tag, 'getSubjectOptions', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getSubjectOptions', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<StudentOptionModel>> getStudentsInClass(String classId) async {
    AppLogger.request(_tag, 'getStudentsInClass', {'classId': classId});
    try {
      final rows = await _client
          .from('class_students')
          .select('student_id, profiles!student_id(full_name)')
          .eq('class_id', classId);

      final students = rows.map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return StudentOptionModel(
          id: row['student_id'] as String,
          name: profile?['full_name'] as String? ?? 'Unknown',
        );
      }).toList();

      students.sort((a, b) => a.name.compareTo(b.name));
      AppLogger.response(_tag, 'getStudentsInClass', students);
      return students;
    } catch (error) {
      AppLogger.error(_tag, 'getStudentsInClass', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<StudentSubmissionEntity>> getAssignmentSubmissions({
    required String assignmentId,
    required String? classId,
  }) async {
    AppLogger.request(_tag, 'getAssignmentSubmissions', {
      'assignmentId': assignmentId,
      'classId': classId,
    });
    if (classId == null) {
      AppLogger.response(_tag, 'getAssignmentSubmissions', <StudentSubmissionEntity>[]);
      return [];
    }

    try {
      final enrollments = await _client
          .from('class_students')
          .select('student_id, profiles(full_name)')
          .eq('class_id', classId);

      final submissionRows = await _client
          .from('submissions')
          .select(
            'id, student_id, status, body_text, auto_score, final_score, status_label, general_feedback, submitted_at',
          )
          .eq('assignment_id', assignmentId)
          .eq('is_current', true);

      final submissionByStudent = {
        for (final row in submissionRows) row['student_id'] as String: row,
      };

      final students = enrollments.map((enrollment) {
        final studentId = enrollment['student_id'] as String;
        final profile = enrollment['profiles'] as Map<String, dynamic>?;
        final studentName = profile?['full_name'] as String? ?? 'Unknown';
        final submission = submissionByStudent[studentId];
        final submittedAt = submission?['submitted_at'] as String?;
        final rawStatusLabel = submission?['status_label'] as String?;
        final bodyText = submission?['body_text'] as String?;

        return StudentSubmissionEntity(
          studentId: studentId,
          studentName: studentName,
          status: submission == null
              ? StudentSubmissionStatus.notSubmitted
              : StudentSubmissionStatus.values.byName(
                  submission['status'] as String,
                ),
          submissionId: submission?['id'] as String?,
          bodyText: bodyText,
          attachmentFileName: bodyText == null
              ? null
              : 'Submission - $studentName.pdf',
          autoScore: (submission?['auto_score'] as num?)?.toInt(),
          finalScore: (submission?['final_score'] as num?)?.toInt(),
          statusLabel: rawStatusLabel == null
              ? null
              : _gradeStatusFromDb(rawStatusLabel),
          generalFeedback: submission?['general_feedback'] as String?,
          submittedAt: submittedAt == null
              ? null
              : DateTime.parse(submittedAt),
        );
      }).toList();

      students.sort((a, b) => a.studentName.compareTo(b.studentName));
      AppLogger.response(_tag, 'getAssignmentSubmissions', students);
      return students;
    } catch (error) {
      AppLogger.error(_tag, 'getAssignmentSubmissions', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<StudentAssignmentEntity>> getStudentAssignments() async {
    AppLogger.request(_tag, 'getStudentAssignments', {
      'studentId': _currentUserId,
    });
    try {
      final enrollments = await _client
          .from('class_students')
          .select('class_id')
          .eq('student_id', _currentUserId)
          .limit(1);

      if (enrollments.isEmpty) {
        AppLogger.response(_tag, 'getStudentAssignments', <StudentAssignmentEntity>[]);
        return [];
      }

      final classId = enrollments.first['class_id'] as String;

      final rows = await _client
          .from('assignments')
          .select(_studentAssignmentSelect)
          .eq('class_id', classId)
          .eq('status', 'published')
          .or('type.is.null,type.eq.assignment')
          .order('due_date');

      final assignmentIds = rows.map((row) => row['id'] as String).toList();

      final submissionRows = assignmentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('submissions')
                .select(
                  'id, assignment_id, status, final_score, status_label, general_feedback, body_text',
                )
                .eq('student_id', _currentUserId)
                .inFilter('assignment_id', assignmentIds)
                .eq('is_current', true);

      final submissionByAssignment = {
        for (final row in submissionRows) row['assignment_id'] as String: row,
      };

      final result = rows.map((row) {
        final assignmentId = row['id'] as String;
        final subject = row['subject'] as Map<String, dynamic>?;
        final teacher = row['teacher'] as Map<String, dynamic>?;
        final rawDueDate = row['due_date'] as String?;
        final submission = submissionByAssignment[assignmentId];
        final rawStatusLabel = submission?['status_label'] as String?;

        return StudentAssignmentEntity(
          id: assignmentId,
          title: row['title'] as String,
          description: row['description'] as String?,
          subject: subject?['title'] as String?,
          teacherName: teacher?['full_name'] as String? ?? 'Unknown',
          teacherId: row['created_by'] as String,
          dueDate: rawDueDate == null ? null : DateTime.parse(rawDueDate),
          submissionStatus: submission == null
              ? StudentSubmissionStatus.notSubmitted
              : StudentSubmissionStatus.values.byName(
                  submission['status'] as String,
                ),
          submissionId: submission?['id'] as String?,
          bodyText: submission?['body_text'] as String?,
          finalScore: (submission?['final_score'] as num?)?.toInt(),
          statusLabel: rawStatusLabel == null
              ? null
              : _gradeStatusFromDb(rawStatusLabel),
          generalFeedback: submission?['general_feedback'] as String?,
        );
      }).toList();
      AppLogger.response(_tag, 'getStudentAssignments', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getStudentAssignments', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> createSubmission(CreateSubmissionParams params) async {
    AppLogger.request(_tag, 'createSubmission', {
      'assignmentId': params.assignmentId,
      'previousSubmissionId': params.previousSubmissionId,
    });
    try {
      final previousId = params.previousSubmissionId;

      if (previousId == null) {
        await _client.from('submissions').insert({
          'assignment_id': params.assignmentId,
          'student_id': _currentUserId,
          'version': 1,
          'is_current': true,
          'status': 'submitted',
          'body_text': params.bodyText,
          'submitted_at': DateTime.now().toIso8601String(),
        });
        AppLogger.response(_tag, 'createSubmission', 'new submission');
        return;
      }

      final previous = await _client
          .from('submissions')
          .select('version')
          .eq('id', previousId)
          .single();
      final nextVersion = (previous['version'] as int) + 1;

      await _client
          .from('submissions')
          .update({'is_current': false})
          .eq('id', previousId);

      await _client.from('submissions').insert({
        'assignment_id': params.assignmentId,
        'student_id': _currentUserId,
        'version': nextVersion,
        'is_current': true,
        'status': 'resubmitted',
        'body_text': params.bodyText,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      await _client.from('notifications').insert({
        'user_id': params.teacherId,
        'type': 'assignment_resubmitted',
        'title': 'Assignment resubmitted',
        'body': 'A student resubmitted "${params.assignmentTitle}".',
        'assignment_id': params.assignmentId,
        'is_read': false,
      });
      AppLogger.response(_tag, 'createSubmission', 'resubmission v$nextVersion');
    } catch (error) {
      AppLogger.error(_tag, 'createSubmission', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<SubmissionAnnotationEntity>> getSubmissionAnnotations(
    String submissionId,
  ) async {
    AppLogger.request(_tag, 'getSubmissionAnnotations', {
      'submissionId': submissionId,
    });
    try {
      final rows = await _client
          .from('annotations')
          .select()
          .eq('submission_id', submissionId)
          .eq('kind', 'pin')
          .order('created_at');

      final result = rows.map(_annotationFromRow).toList();
      AppLogger.response(_tag, 'getSubmissionAnnotations', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getSubmissionAnnotations', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<SubmissionAnnotationEntity> addAnnotation(
    AddAnnotationParams params,
  ) async {
    AppLogger.request(_tag, 'addAnnotation', {
      'submissionId': params.submissionId,
    });
    try {
      final row = await _client
          .from('annotations')
          .insert({
            'submission_id': params.submissionId,
            'kind': 'pin',
            'x_percent': params.xPercent,
            'y_percent': params.yPercent,
            'text': params.text,
            'created_by': _currentUserId,
          })
          .select()
          .single();

      final result = _annotationFromRow(row);
      AppLogger.response(_tag, 'addAnnotation', result.id);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'addAnnotation', error);
      throw ServerException(error.toString());
    }
  }

  SubmissionAnnotationEntity _annotationFromRow(Map<String, dynamic> row) {
    return SubmissionAnnotationEntity(
      id: row['id'] as String,
      xPercent: (row['x_percent'] as num).toDouble(),
      yPercent: (row['y_percent'] as num).toDouble(),
      text: row['text'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<void> updateAnnotationText(String annotationId, String text) async {
    AppLogger.request(_tag, 'updateAnnotationText', {
      'annotationId': annotationId,
    });
    try {
      await _client
          .from('annotations')
          .update({'text': text})
          .eq('id', annotationId);
      AppLogger.response(_tag, 'updateAnnotationText');
    } catch (error) {
      AppLogger.error(_tag, 'updateAnnotationText', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteAnnotation(String annotationId) async {
    AppLogger.request(_tag, 'deleteAnnotation', {
      'annotationId': annotationId,
    });
    try {
      await _client.from('annotations').delete().eq('id', annotationId);
      AppLogger.response(_tag, 'deleteAnnotation');
    } catch (error) {
      AppLogger.error(_tag, 'deleteAnnotation', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> gradeSubmission(GradeSubmissionParams params) async {
    AppLogger.request(_tag, 'gradeSubmission', {
      'submissionId': params.submissionId,
      'returnToStudent': params.returnToStudent,
    });
    try {
      final payload = <String, dynamic>{
        'final_score': params.finalScore,
        'status_label': _gradeStatusToDb(params.statusLabel),
        'general_feedback': params.generalFeedback,
        'graded_by': _currentUserId,
      };

      if (params.returnToStudent) {
        payload['status'] = 'returned';
        payload['returned_at'] = DateTime.now().toIso8601String();
      }

      final row = await _client
          .from('submissions')
          .update(payload)
          .eq('id', params.submissionId)
          .select('student_id, assignment_id, assignments(title)')
          .single();

      if (params.returnToStudent) {
        final assignment = row['assignments'] as Map<String, dynamic>?;
        final assignmentTitle = assignment?['title'] as String? ?? 'your assignment';
        final studentId = row['student_id'] as String;

        await _client.from('notifications').insert({
          'user_id': studentId,
          'type': 'assignment_returned',
          'title': 'Assignment graded',
          'body': 'Your teacher graded and returned "$assignmentTitle".',
          'assignment_id': row['assignment_id'],
          'submission_id': params.submissionId,
          'is_read': false,
        });

        final parentRows = await _client
            .from('parent_student')
            .select('parent_id')
            .eq('student_id', studentId);

        if (parentRows.isNotEmpty) {
          await _client.from('notifications').insert([
            for (final parentRow in parentRows)
              {
                'user_id': parentRow['parent_id'],
                'type': 'assignment_returned',
                'title': 'Your child was graded',
                'body':
                    'A submission for "$assignmentTitle" was graded and returned.',
                'assignment_id': row['assignment_id'],
                'submission_id': params.submissionId,
                'is_read': false,
              },
          ]);
        }
        AppLogger.response(
          _tag,
          'gradeSubmission',
          'returned, ${parentRows.length} parent notification(s)',
        );
      } else {
        AppLogger.response(_tag, 'gradeSubmission', 'saved, not returned');
      }
    } catch (error) {
      AppLogger.error(_tag, 'gradeSubmission', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<AssignmentModel>> getTeacherCbts() async {
    AppLogger.request(_tag, 'getTeacherCbts', {'teacherId': _currentUserId});
    try {
      final rows = await _client
          .from('assignments')
          .select(_assignmentSelect)
          .eq('created_by', _currentUserId)
          .eq('type', 'cbt')
          .order('created_at', ascending: false);

      final assignmentIds = rows.map((row) => row['id'] as String).toList();
      final counts = await _submittedCounts(assignmentIds);

      final result = rows.map((row) {
        return AssignmentModel.fromJson({
          ...row,
          '_submitted_count': counts[row['id']] ?? 0,
        });
      }).toList();
      AppLogger.response(_tag, 'getTeacherCbts', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getTeacherCbts', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<StudentAssignmentEntity>> getStudentCbts() async {
    AppLogger.request(_tag, 'getStudentCbts', {'studentId': _currentUserId});
    try {
      final enrollments = await _client
          .from('class_students')
          .select('class_id')
          .eq('student_id', _currentUserId)
          .limit(1);

      if (enrollments.isEmpty) {
        AppLogger.response(_tag, 'getStudentCbts', <StudentAssignmentEntity>[]);
        return [];
      }

      final classId = enrollments.first['class_id'] as String;

      final rows = await _client
          .from('assignments')
          .select(_studentAssignmentSelect)
          .eq('class_id', classId)
          .eq('status', 'published')
          .eq('type', 'cbt')
          .order('due_date');

      final assignmentIds = rows.map((row) => row['id'] as String).toList();

      final submissionRows = assignmentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('submissions')
                .select(
                  'id, assignment_id, status, auto_score, final_score, status_label, general_feedback',
                )
                .eq('student_id', _currentUserId)
                .inFilter('assignment_id', assignmentIds)
                .eq('is_current', true);

      final submissionByAssignment = {
        for (final row in submissionRows) row['assignment_id'] as String: row,
      };

      final result = rows.map((row) {
        final assignmentId = row['id'] as String;
        final subject = row['subject'] as Map<String, dynamic>?;
        final teacher = row['teacher'] as Map<String, dynamic>?;
        final rawDueDate = row['due_date'] as String?;
        final submission = submissionByAssignment[assignmentId];
        final rawStatusLabel = submission?['status_label'] as String?;

        return StudentAssignmentEntity(
          id: assignmentId,
          title: row['title'] as String,
          description: row['description'] as String?,
          subject: subject?['title'] as String?,
          teacherName: teacher?['full_name'] as String? ?? 'Unknown',
          teacherId: row['created_by'] as String,
          dueDate: rawDueDate == null ? null : DateTime.parse(rawDueDate),
          submissionStatus: submission == null
              ? StudentSubmissionStatus.notSubmitted
              : StudentSubmissionStatus.values.byName(
                  submission['status'] as String,
                ),
          submissionId: submission?['id'] as String?,
          finalScore: (submission?['final_score'] as num?)?.toInt(),
          statusLabel: rawStatusLabel == null
              ? null
              : _gradeStatusFromDb(rawStatusLabel),
          generalFeedback: submission?['general_feedback'] as String?,
        );
      }).toList();
      AppLogger.response(_tag, 'getStudentCbts', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getStudentCbts', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<AssignmentModel> createCbt(CreateCbtInput input) async {
    AppLogger.request(_tag, 'createCbt', {
      'title': input.data.title,
      'questionCount': input.questions.length,
    });
    try {
      final row = await _client
          .from('assignments')
          .insert({
            'type': 'cbt',
            'status': 'published',
            'created_by': _currentUserId,
            ..._assignmentPayload(input.data),
          })
          .select(_assignmentSelect)
          .single();

      final assignmentId = row['id'] as String;
      await _syncQuestions(assignmentId, input.questions);

      final result = AssignmentModel.fromJson({...row, '_submitted_count': 0});
      AppLogger.response(_tag, 'createCbt', result.id);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'createCbt', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<AssignmentModel> updateCbt(UpdateCbtInput input) async {
    AppLogger.request(_tag, 'updateCbt', {
      'id': input.id,
      'questionCount': input.questions.length,
    });
    try {
      final row = await _client
          .from('assignments')
          .update(_assignmentPayload(input.data))
          .eq('id', input.id)
          .select(_assignmentSelect)
          .single();

      await _client.from('questions').delete().eq('assignment_id', input.id);
      await _syncQuestions(input.id, input.questions);

      final counts = await _submittedCounts([input.id]);

      final result = AssignmentModel.fromJson({
        ...row,
        '_submitted_count': counts[input.id] ?? 0,
      });
      AppLogger.response(_tag, 'updateCbt', result.id);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'updateCbt', error);
      throw ServerException(error.toString());
    }
  }

  Future<void> _syncQuestions(
    String assignmentId,
    List<QuestionDraft> questions,
  ) async {
    for (var i = 0; i < questions.length; i++) {
      final draft = questions[i];

      final questionRow = await _client
          .from('questions')
          .insert({
            'assignment_id': assignmentId,
            'type': _questionTypeToDb(draft.type),
            'prompt': draft.prompt,
            'points': draft.points,
            'position': i,
            'correct_bool': draft.correctBool,
            'model_answer': draft.modelAnswer,
          })
          .select('id')
          .single();

      if (draft.options.isEmpty) continue;

      final questionId = questionRow['id'] as String;
      await _client.from('question_options').insert([
        for (var j = 0; j < draft.options.length; j++)
          {
            'question_id': questionId,
            'label': draft.options[j].label,
            'is_correct': draft.options[j].isCorrect,
            'position': j,
          },
      ]);
    }
  }

  @override
  Future<List<QuestionEntity>> getQuestions(String assignmentId) async {
    AppLogger.request(_tag, 'getQuestions', {'assignmentId': assignmentId});
    try {
      final rows = await _client
          .from('questions')
          .select('*, question_options(*)')
          .eq('assignment_id', assignmentId)
          .order('position');

      final result = rows.map(_questionFromRow).toList();
      AppLogger.response(_tag, 'getQuestions', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getQuestions', error);
      throw ServerException(error.toString());
    }
  }

  QuestionEntity _questionFromRow(Map<String, dynamic> row) {
    final optionRows = ((row['question_options'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort(
        (a, b) => (a['position'] as int).compareTo(b['position'] as int),
      );

    return QuestionEntity(
      id: row['id'] as String,
      type: _questionTypeFromDb(row['type'] as String),
      prompt: row['prompt'] as String,
      points: (row['points'] as num).toInt(),
      position: row['position'] as int,
      correctBool: row['correct_bool'] as bool?,
      modelAnswer: row['model_answer'] as String?,
      options: optionRows
          .map(
            (option) => QuestionOptionEntity(
              id: option['id'] as String,
              label: option['label'] as String,
              isCorrect: option['is_correct'] as bool,
              position: option['position'] as int,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> submitCbtAnswers(SubmitCbtParams params) async {
    AppLogger.request(_tag, 'submitCbtAnswers', {
      'assignmentId': params.assignmentId,
      'answerCount': params.answers.length,
    });
    try {
      final questions = await getQuestions(params.assignmentId);
      final questionsById = {for (final q in questions) q.id: q};

      final submissionRow = await _client
          .from('submissions')
          .insert({
            'assignment_id': params.assignmentId,
            'student_id': _currentUserId,
            'version': 1,
            'is_current': true,
            'status': 'submitted',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      final submissionId = submissionRow['id'] as String;

      var autoScore = 0;
      final answerRows = <Map<String, dynamic>>[];

      for (final answer in params.answers) {
        final question = questionsById[answer.questionId];
        if (question == null) continue;

        bool? isCorrect;
        int? awardedPoints;

        switch (question.type) {
          case QuestionType.mcq:
            final selected = question.options
                .where((option) => option.id == answer.selectedOptionId)
                .toList();
            isCorrect = selected.isNotEmpty && selected.first.isCorrect;
            awardedPoints = isCorrect ? question.points : 0;
          case QuestionType.tf:
            isCorrect =
                answer.answerBool != null &&
                answer.answerBool == question.correctBool;
            awardedPoints = isCorrect ? question.points : 0;
          case QuestionType.shortAnswer:
            isCorrect = null;
            awardedPoints = null;
        }

        if (awardedPoints != null) autoScore += awardedPoints;

        answerRows.add({
          'submission_id': submissionId,
          'question_id': answer.questionId,
          'selected_option_id': answer.selectedOptionId,
          'answer_bool': answer.answerBool,
          'answer_text': answer.answerText,
          'is_correct': isCorrect,
          'awarded_points': awardedPoints,
        });
      }

      await _client.from('submission_answers').insert(answerRows);
      await _client
          .from('submissions')
          .update({'auto_score': autoScore})
          .eq('id', submissionId);
      AppLogger.response(_tag, 'submitCbtAnswers', 'autoScore=$autoScore');
    } catch (error) {
      AppLogger.error(_tag, 'submitCbtAnswers', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<SubmissionAnswerEntity>> getSubmissionAnswers(
    String submissionId,
  ) async {
    AppLogger.request(_tag, 'getSubmissionAnswers', {
      'submissionId': submissionId,
    });
    try {
      final rows = await _client
          .from('submission_answers')
          .select()
          .eq('submission_id', submissionId);

      final result = rows.map((row) {
        return SubmissionAnswerEntity(
          id: row['id'] as String,
          questionId: row['question_id'] as String,
          selectedOptionId: row['selected_option_id'] as String?,
          answerBool: row['answer_bool'] as bool?,
          answerText: row['answer_text'] as String?,
          isCorrect: row['is_correct'] as bool?,
          awardedPoints: (row['awarded_points'] as num?)?.toInt(),
        );
      }).toList();
      AppLogger.response(_tag, 'getSubmissionAnswers', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getSubmissionAnswers', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> gradeCbtAnswers(List<CbtAnswerGrade> grades) async {
    AppLogger.request(_tag, 'gradeCbtAnswers', {'count': grades.length});
    try {
      for (final grade in grades) {
        await _client
            .from('submission_answers')
            .update({
              'awarded_points': grade.awardedPoints,
              'is_correct': grade.awardedPoints > 0,
            })
            .eq('id', grade.answerId);
      }
      AppLogger.response(_tag, 'gradeCbtAnswers');
    } catch (error) {
      AppLogger.error(_tag, 'gradeCbtAnswers', error);
      throw ServerException(error.toString());
    }
  }
}
