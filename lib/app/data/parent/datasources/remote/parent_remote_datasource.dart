import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';

abstract class ParentRemoteDataSource {
  Future<List<StudentSummaryEntity>> getChildren();

  Future<StudentDetailEntity> getChildDetail(String childId);
}

class ParentRemoteDataSourceImpl implements ParentRemoteDataSource {
  const ParentRemoteDataSourceImpl(this._client);

  static const _tag = 'ParentRemoteDataSource';

  final SupabaseClient _client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppAuthException('You are not signed in.');
    }
    return id;
  }

  @override
  Future<List<StudentSummaryEntity>> getChildren() async {
    AppLogger.request(_tag, 'getChildren', {
      'parentId': _currentUserId,
    });
    try {
      final linkRows = await _client
          .from('parent_student')
          .select('student_id')
          .eq('parent_id', _currentUserId);

      final childIds = linkRows
          .map((row) => row['student_id'] as String)
          .toList();
      AppLogger.state(_tag, 'getChildren: ${childIds.length} linked child id(s)');
      if (childIds.isEmpty) {
        AppLogger.response(_tag, 'getChildren', <StudentSummaryEntity>[]);
        return [];
      }

      final studentRows = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', childIds)
          .order('full_name');
      AppLogger.state(_tag, 'getChildren: ${studentRows.length} student profile(s)');

      final enrollmentRows = await _client
          .from('class_students')
          .select('student_id, classes(name)')
          .inFilter('student_id', childIds);

      final classNameByStudent = <String, String>{};
      for (final row in enrollmentRows) {
        final cls = row['classes'] as Map<String, dynamic>?;
        if (cls != null) {
          classNameByStudent[row['student_id'] as String] =
              cls['name'] as String;
        }
      }

      final submissionRows = await _client
          .from('submissions')
          .select(
            'student_id, assignment_id, final_score, assignments(type, rubric_criteria)',
          )
          .inFilter('student_id', childIds)
          .eq('is_current', true);
      AppLogger.state(
        _tag,
        'getChildren: ${submissionRows.length} current submission(s)',
      );

      final questionBasedAssignmentIds = <String>{};
      for (final row in submissionRows) {
        if (row['final_score'] == null) continue;
        final assignment = row['assignments'] as Map<String, dynamic>?;
        if ((assignment?['type'] as String?) != 'assignment') {
          questionBasedAssignmentIds.add(row['assignment_id'] as String);
        }
      }

      final maxPointsByAssignment = <String, int>{};
      if (questionBasedAssignmentIds.isNotEmpty) {
        final questionRows = await _client
            .from('questions')
            .select('assignment_id, points')
            .inFilter('assignment_id', questionBasedAssignmentIds.toList());
        AppLogger.state(
          _tag,
          'getChildren: ${questionRows.length} question(s) for '
          '${questionBasedAssignmentIds.length} CBT/quick-test assignment(s)',
        );
        for (final row in questionRows) {
          final assignmentId = row['assignment_id'] as String;
          final points = (row['points'] as num?)?.toInt() ?? 0;
          maxPointsByAssignment[assignmentId] =
              (maxPointsByAssignment[assignmentId] ?? 0) + points;
        }
      }

      final percentagesByStudent = <String, List<double>>{};
      for (final row in submissionRows) {
        final score = row['final_score'] as num?;
        if (score == null) continue;

        final assignmentId = row['assignment_id'] as String;
        final assignment = row['assignments'] as Map<String, dynamic>?;
        final isRubricBased =
            (assignment?['type'] as String?) == 'assignment';

        final maxScore = isRubricBased
            ? (assignment?['rubric_criteria'] as List<dynamic>? ?? const [])
                  .fold<int>(
                    0,
                    (sum, item) =>
                        sum +
                        (((item as Map<String, dynamic>)['max_points']
                                    as num?)
                                ?.toInt() ??
                            0),
                  )
            : (maxPointsByAssignment[assignmentId] ?? 0);
        if (maxScore <= 0) continue;

        final percentage = (score / maxScore * 100).clamp(0, 100).toDouble();
        final id = row['student_id'] as String;
        (percentagesByStudent[id] ??= []).add(percentage);
      }

      final result = studentRows.map((row) {
        final id = row['id'] as String;
        final percentages = percentagesByStudent[id];
        final average = (percentages == null || percentages.isEmpty)
            ? null
            : percentages.reduce((a, b) => a + b) / percentages.length;

        return StudentSummaryEntity(
          id: id,
          name: row['full_name'] as String? ?? 'Unknown',
          className: classNameByStudent[id],
          averageScore: average,
        );
      }).toList();
      AppLogger.response(_tag, 'getChildren', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getChildren', error);
      throw ServerException(error.toString());
    }
  }

  @override
  Future<StudentDetailEntity> getChildDetail(String childId) async {
    AppLogger.request(_tag, 'getChildDetail', {'childId': childId});
    try {
      final profileRow = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('id', childId)
          .single();

      final enrollmentRows = await _client
          .from('class_students')
          .select('classes(name)')
          .eq('student_id', childId)
          .limit(1);

      final className = enrollmentRows.isEmpty
          ? null
          : (enrollmentRows.first['classes'] as Map<String, dynamic>?)?['name']
                as String?;

      final submissionRows = await _client
          .from('submissions')
          .select('id, status, final_score, submitted_at, assignments(title, type)')
          .eq('student_id', childId)
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

      final result = StudentDetailEntity(
        id: profileRow['id'] as String,
        name: profileRow['full_name'] as String? ?? 'Unknown',
        className: className,
        assessments: assessments,
      );
      AppLogger.response(_tag, 'getChildDetail', result.assessments);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'getChildDetail', error);
      throw ServerException(error.toString());
    }
  }
}
