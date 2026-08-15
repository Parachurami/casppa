import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/data/assignments/models/assignment_model.dart';
import 'package:casppa/app/data/assignments/models/class_option_model.dart';
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
  Future<AssignmentModel> createAssignment(
    CreateAssignmentParams params,
  ) async {
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

      return AssignmentModel.fromJson({...row, '_submitted_count': 0});
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<AssignmentModel> updateAssignment(
    String id,
    CreateAssignmentParams params,
  ) async {
    try {
      final row = await _client
          .from('assignments')
          .update(_assignmentPayload(params))
          .eq('id', id)
          .select(_assignmentSelect)
          .single();

      final counts = await _submittedCounts([id]);

      return AssignmentModel.fromJson({
        ...row,
        '_submitted_count': counts[id] ?? 0,
      });
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteAssignment(String id) async {
    try {
      await _client.from('assignments').delete().eq('id', id);
    } catch (error) {
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
    try {
      final rows = await _client
          .from('classes')
          .select()
          .eq('teacher_id', _currentUserId)
          .order('name');

      return rows.map(ClassOptionModel.fromJson).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<ClassOptionModel>> getAllClassOptions() async {
    try {
      final rows = await _client.from('classes').select().order('name');

      return rows.map(ClassOptionModel.fromJson).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<SubjectOptionModel>> getSubjectOptions() async {
    try {
      final rows = await _client.from('subjects').select().order('title');

      return rows.map(SubjectOptionModel.fromJson).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<StudentSubmissionEntity>> getAssignmentSubmissions({
    required String assignmentId,
    required String? classId,
  }) async {
    if (classId == null) return [];

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
      return students;
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<StudentAssignmentEntity>> getStudentAssignments() async {
    try {
      final enrollments = await _client
          .from('class_students')
          .select('class_id')
          .eq('student_id', _currentUserId)
          .limit(1);

      if (enrollments.isEmpty) return [];

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

      return rows.map((row) {
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
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> createSubmission(CreateSubmissionParams params) async {
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
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<SubmissionAnnotationEntity>> getSubmissionAnnotations(
    String submissionId,
  ) async {
    try {
      final rows = await _client
          .from('annotations')
          .select()
          .eq('submission_id', submissionId)
          .eq('kind', 'pin')
          .order('created_at');

      return rows.map(_annotationFromRow).toList();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<SubmissionAnnotationEntity> addAnnotation(
    AddAnnotationParams params,
  ) async {
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

      return _annotationFromRow(row);
    } catch (error) {
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
    try {
      await _client
          .from('annotations')
          .update({'text': text})
          .eq('id', annotationId);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> deleteAnnotation(String annotationId) async {
    try {
      await _client.from('annotations').delete().eq('id', annotationId);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> gradeSubmission(GradeSubmissionParams params) async {
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

        await _client.from('notifications').insert({
          'user_id': row['student_id'],
          'type': 'assignment_returned',
          'title': 'Assignment graded',
          'body': 'Your teacher graded and returned "$assignmentTitle".',
          'assignment_id': row['assignment_id'],
          'submission_id': params.submissionId,
          'is_read': false,
        });
      }
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<AssignmentModel>> getTeacherCbts() async {
    try {
      final rows = await _client
          .from('assignments')
          .select(_assignmentSelect)
          .eq('created_by', _currentUserId)
          .eq('type', 'cbt')
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

  @override
  Future<List<StudentAssignmentEntity>> getStudentCbts() async {
    try {
      final enrollments = await _client
          .from('class_students')
          .select('class_id')
          .eq('student_id', _currentUserId)
          .limit(1);

      if (enrollments.isEmpty) return [];

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

      return rows.map((row) {
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
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<AssignmentModel> createCbt(CreateCbtInput input) async {
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

      return AssignmentModel.fromJson({...row, '_submitted_count': 0});
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<AssignmentModel> updateCbt(UpdateCbtInput input) async {
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

      return AssignmentModel.fromJson({
        ...row,
        '_submitted_count': counts[input.id] ?? 0,
      });
    } catch (error) {
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
    try {
      final rows = await _client
          .from('questions')
          .select('*, question_options(*)')
          .eq('assignment_id', assignmentId)
          .order('position');

      return rows.map(_questionFromRow).toList();
    } catch (error) {
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
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<SubmissionAnswerEntity>> getSubmissionAnswers(
    String submissionId,
  ) async {
    try {
      final rows = await _client
          .from('submission_answers')
          .select()
          .eq('submission_id', submissionId);

      return rows.map((row) {
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
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> gradeCbtAnswers(List<CbtAnswerGrade> grades) async {
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
    } catch (error) {
      throw ServerException(error.toString());
    }
  }
}
