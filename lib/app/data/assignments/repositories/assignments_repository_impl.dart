import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/assignments/datasources/local/assignments_local_datasource.dart';
import 'package:casppa/app/data/assignments/datasources/remote/assignments_remote_datasource.dart';
import 'package:casppa/app/data/assignments/models/assignment_model.dart';
import 'package:casppa/app/data/assignments/models/class_option_model.dart';
import 'package:casppa/app/data/assignments/models/subject_option_model.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/grade_status.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_answer_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/domain/assignments/params/add_annotation_params.dart';
import 'package:casppa/app/domain/assignments/params/assignment_submissions_params.dart';
import 'package:casppa/app/domain/assignments/params/cbt_answer_grade.dart';
import 'package:casppa/app/domain/assignments/params/cbt_input.dart';
import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/params/create_submission_params.dart';
import 'package:casppa/app/domain/assignments/params/grade_submission_params.dart';
import 'package:casppa/app/domain/assignments/params/submit_cbt_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class AssignmentsRepositoryImpl implements AssignmentsRepository {
  const AssignmentsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  static const _tag = 'AssignmentsRepository';

  final AssignmentsRemoteDataSource _remoteDataSource;
  final AssignmentsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<List<AssignmentEntity>> getTeacherAssignments() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getTeacherAssignments: online, fetching remote');
      try {
        final assignments = await _remoteDataSource.getTeacherAssignments();
        AppLogger.state(
          _tag,
          'getTeacherAssignments: remote returned ${assignments.length}, caching',
        );
        await _localDataSource.cacheList(
          HiveKeys.cachedAssignments,
          assignments.map(_toCacheJson).toList(),
        );
        return Right(assignments);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getTeacherAssignments', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getTeacherAssignments: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedList(
        HiveKeys.cachedAssignments,
      );
      return Right(cached.map(AssignmentModel.fromJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getTeacherAssignments', error);
      return Left(CacheFailure(error.message));
    }
  }

  DataMap _toCacheJson(AssignmentModel assignment) {
    return {
      'id': assignment.id,
      'type': assignment.type.name,
      'status': assignment.status.name,
      'title': assignment.title,
      'description': assignment.description,
      'class_id': assignment.classId,
      'class': assignment.className == null
          ? null
          : {'name': assignment.className},
      'subject': assignment.subject == null
          ? null
          : {'title': assignment.subject},
      'due_date': assignment.dueDate?.toIso8601String(),
      'created_by': assignment.createdBy,
      'expected_submissions': assignment.expectedSubmissions,
      '_submitted_count': assignment.submittedCount,
      'rubric_criteria': assignment.rubricCriteria
          .map((c) => {'name': c.name, 'max_points': c.maxPoints})
          .toList(),
    };
  }

  DataMap _classOptionToCacheJson(ClassOptionEntity option) {
    return {'id': option.id, 'name': option.name};
  }

  DataMap _subjectOptionToCacheJson(SubjectOptionEntity option) {
    return {'id': option.id, 'title': option.title};
  }

  DataMap _studentAssignmentToCacheJson(StudentAssignmentEntity assignment) {
    return {
      'id': assignment.id,
      'title': assignment.title,
      'description': assignment.description,
      'subject': assignment.subject,
      'teacher_name': assignment.teacherName,
      'teacher_id': assignment.teacherId,
      'due_date': assignment.dueDate?.toIso8601String(),
      'submission_status': assignment.submissionStatus.name,
      'submission_id': assignment.submissionId,
      'body_text': assignment.bodyText,
      'final_score': assignment.finalScore,
      'status_label': assignment.statusLabel?.name,
      'general_feedback': assignment.generalFeedback,
    };
  }

  StudentAssignmentEntity _studentAssignmentFromCacheJson(DataMap json) {
    final rawDueDate = json['due_date'] as String?;
    final rawStatusLabel = json['status_label'] as String?;

    return StudentAssignmentEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      teacherName: json['teacher_name'] as String,
      teacherId: json['teacher_id'] as String,
      dueDate: rawDueDate == null ? null : DateTime.parse(rawDueDate),
      submissionStatus: StudentSubmissionStatus.values.byName(
        json['submission_status'] as String,
      ),
      submissionId: json['submission_id'] as String?,
      bodyText: json['body_text'] as String?,
      finalScore: (json['final_score'] as num?)?.toInt(),
      statusLabel: rawStatusLabel == null
          ? null
          : GradeStatus.values.byName(rawStatusLabel),
      generalFeedback: json['general_feedback'] as String?,
    );
  }

  @override
  ResultFuture<AssignmentEntity> createAssignment(
    CreateAssignmentParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'createAssignment: offline, cannot create');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'createAssignment(${params.title}): online, calling remote',
    );
    try {
      final assignment = await _remoteDataSource.createAssignment(params);
      return Right(assignment);
    } on AppAuthException catch (error) {
      AppLogger.error(_tag, 'createAssignment', error);
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'createAssignment', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<AssignmentEntity> updateAssignment(
    String id,
    CreateAssignmentParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'updateAssignment: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'updateAssignment($id): online, calling remote');
    try {
      final assignment = await _remoteDataSource.updateAssignment(id, params);
      return Right(assignment);
    } on AppAuthException catch (error) {
      AppLogger.error(_tag, 'updateAssignment', error);
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'updateAssignment', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteAssignment(String id) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'deleteAssignment: offline, cannot delete');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'deleteAssignment($id): online, calling remote');
    try {
      await _remoteDataSource.deleteAssignment(id);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'deleteAssignment', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<ClassOptionEntity>> getClassOptions() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getClassOptions: online, fetching remote');
      try {
        final options = await _remoteDataSource.getClassOptions();
        AppLogger.state(
          _tag,
          'getClassOptions: remote returned ${options.length}, caching',
        );
        await _localDataSource.cacheList(
          HiveKeys.cachedClassOptions,
          options.map(_classOptionToCacheJson).toList(),
        );
        return Right(options);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getClassOptions', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getClassOptions: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedList(
        HiveKeys.cachedClassOptions,
      );
      return Right(cached.map(ClassOptionModel.fromJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getClassOptions', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<List<ClassOptionEntity>> getAllClassOptions() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getAllClassOptions: online, fetching remote');
      try {
        final options = await _remoteDataSource.getAllClassOptions();
        AppLogger.state(
          _tag,
          'getAllClassOptions: remote returned ${options.length}, caching',
        );
        await _localDataSource.cacheList(
          HiveKeys.cachedAllClassOptions,
          options.map(_classOptionToCacheJson).toList(),
        );
        return Right(options);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getAllClassOptions', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getAllClassOptions: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedList(
        HiveKeys.cachedAllClassOptions,
      );
      return Right(cached.map(ClassOptionModel.fromJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getAllClassOptions', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubjectOptionEntity>> getSubjectOptions() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getSubjectOptions: online, fetching remote');
      try {
        final options = await _remoteDataSource.getSubjectOptions();
        AppLogger.state(
          _tag,
          'getSubjectOptions: remote returned ${options.length}, caching',
        );
        await _localDataSource.cacheList(
          HiveKeys.cachedSubjectOptions,
          options.map(_subjectOptionToCacheJson).toList(),
        );
        return Right(options);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getSubjectOptions', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getSubjectOptions: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedList(
        HiveKeys.cachedSubjectOptions,
      );
      return Right(cached.map(SubjectOptionModel.fromJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getSubjectOptions', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentOptionEntity>> getStudentsInClass(
    String classId,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getStudentsInClass: offline, no cache');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'getStudentsInClass($classId): online, calling remote');
    try {
      final students = await _remoteDataSource.getStudentsInClass(classId);
      return Right(students);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getStudentsInClass', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentSubmissionEntity>> getAssignmentSubmissions(
    AssignmentSubmissionsParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getAssignmentSubmissions: offline, no cache');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'getAssignmentSubmissions(${params.assignmentId}): online, calling remote',
    );
    try {
      final submissions = await _remoteDataSource.getAssignmentSubmissions(
        assignmentId: params.assignmentId,
        classId: params.classId,
      );
      return Right(submissions);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getAssignmentSubmissions', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentAssignmentEntity>> getStudentAssignments() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getStudentAssignments: online, fetching remote');
      try {
        final assignments = await _remoteDataSource.getStudentAssignments();
        AppLogger.state(
          _tag,
          'getStudentAssignments: remote returned ${assignments.length}, caching',
        );
        await _localDataSource.cacheList(
          HiveKeys.cachedStudentAssignments,
          assignments.map(_studentAssignmentToCacheJson).toList(),
        );
        return Right(assignments);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getStudentAssignments', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getStudentAssignments: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedList(
        HiveKeys.cachedStudentAssignments,
      );
      return Right(cached.map(_studentAssignmentFromCacheJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getStudentAssignments', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultVoid createSubmission(CreateSubmissionParams params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'createSubmission: offline, cannot submit');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'createSubmission(${params.assignmentId}): online, calling remote',
    );
    try {
      await _remoteDataSource.createSubmission(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'createSubmission', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubmissionAnnotationEntity>> getSubmissionAnnotations(
    String submissionId,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getSubmissionAnnotations: offline, no cache');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'getSubmissionAnnotations($submissionId): online, calling remote',
    );
    try {
      final annotations = await _remoteDataSource.getSubmissionAnnotations(
        submissionId,
      );
      return Right(annotations);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getSubmissionAnnotations', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<SubmissionAnnotationEntity> addAnnotation(
    AddAnnotationParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'addAnnotation: offline, cannot add');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'addAnnotation: online, calling remote');
    try {
      final annotation = await _remoteDataSource.addAnnotation(params);
      return Right(annotation);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'addAnnotation', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid updateAnnotationText(String annotationId, String text) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'updateAnnotationText: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'updateAnnotationText($annotationId): online, calling remote',
    );
    try {
      await _remoteDataSource.updateAnnotationText(annotationId, text);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'updateAnnotationText', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteAnnotation(String annotationId) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'deleteAnnotation: offline, cannot delete');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'deleteAnnotation($annotationId): online, calling remote');
    try {
      await _remoteDataSource.deleteAnnotation(annotationId);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'deleteAnnotation', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid gradeSubmission(GradeSubmissionParams params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'gradeSubmission: offline, cannot grade');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'gradeSubmission(${params.submissionId}): online, calling remote',
    );
    try {
      await _remoteDataSource.gradeSubmission(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'gradeSubmission', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<AssignmentEntity>> getTeacherCbts() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getTeacherCbts: online, fetching remote');
      try {
        final cbts = await _remoteDataSource.getTeacherCbts();
        AppLogger.state(
          _tag,
          'getTeacherCbts: remote returned ${cbts.length}, caching',
        );
        await _localDataSource.cacheList(
          HiveKeys.cachedTeacherCbts,
          cbts.map(_toCacheJson).toList(),
        );
        return Right(cbts);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getTeacherCbts', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getTeacherCbts: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedList(
        HiveKeys.cachedTeacherCbts,
      );
      return Right(cached.map(AssignmentModel.fromJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getTeacherCbts', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentAssignmentEntity>> getStudentCbts() async {
    if (await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getStudentCbts: online, fetching remote');
      try {
        final cbts = await _remoteDataSource.getStudentCbts();
        AppLogger.state(
          _tag,
          'getStudentCbts: remote returned ${cbts.length}, caching',
        );
        await _localDataSource.cacheList(
          HiveKeys.cachedStudentCbts,
          cbts.map(_studentAssignmentToCacheJson).toList(),
        );
        return Right(cbts);
      } on ServerException catch (error) {
        AppLogger.error(_tag, 'getStudentCbts', error);
        return Left(ServerFailure(error.message));
      }
    }

    AppLogger.state(_tag, 'getStudentCbts: offline, reading cache');
    try {
      final cached = await _localDataSource.getCachedList(
        HiveKeys.cachedStudentCbts,
      );
      return Right(cached.map(_studentAssignmentFromCacheJson).toList());
    } on CacheException catch (error) {
      AppLogger.error(_tag, 'getStudentCbts', error);
      return Left(CacheFailure(error.message));
    }
  }

  @override
  ResultFuture<AssignmentEntity> createCbt(CreateCbtInput input) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'createCbt: offline, cannot create');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'createCbt: online, calling remote');
    try {
      final cbt = await _remoteDataSource.createCbt(input);
      return Right(cbt);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'createCbt', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<AssignmentEntity> updateCbt(UpdateCbtInput input) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'updateCbt: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'updateCbt: online, calling remote');
    try {
      final cbt = await _remoteDataSource.updateCbt(input);
      return Right(cbt);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'updateCbt', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<QuestionEntity>> getQuestions(String assignmentId) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getQuestions: offline, no cache');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(_tag, 'getQuestions($assignmentId): online, calling remote');
    try {
      final questions = await _remoteDataSource.getQuestions(assignmentId);
      return Right(questions);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getQuestions', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid submitCbtAnswers(SubmitCbtParams params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'submitCbtAnswers: offline, cannot submit');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'submitCbtAnswers(${params.assignmentId}): online, calling remote',
    );
    try {
      await _remoteDataSource.submitCbtAnswers(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'submitCbtAnswers', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubmissionAnswerEntity>> getSubmissionAnswers(
    String submissionId,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getSubmissionAnswers: offline, no cache');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'getSubmissionAnswers($submissionId): online, calling remote',
    );
    try {
      final answers = await _remoteDataSource.getSubmissionAnswers(
        submissionId,
      );
      return Right(answers);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getSubmissionAnswers', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid gradeCbtAnswers(List<CbtAnswerGrade> grades) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'gradeCbtAnswers: offline, cannot grade');
      return const Left(NetworkFailure('No internet connection.'));
    }

    AppLogger.state(
      _tag,
      'gradeCbtAnswers(${grades.length} grade(s)): online, calling remote',
    );
    try {
      await _remoteDataSource.gradeCbtAnswers(grades);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'gradeCbtAnswers', error);
      return Left(ServerFailure(error.message));
    }
  }
}
