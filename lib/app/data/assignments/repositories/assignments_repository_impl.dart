import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/assignments/datasources/local/assignments_local_datasource.dart';
import 'package:casppa/app/data/assignments/datasources/remote/assignments_remote_datasource.dart';
import 'package:casppa/app/data/assignments/models/assignment_model.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
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

  final AssignmentsRemoteDataSource _remoteDataSource;
  final AssignmentsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<List<AssignmentEntity>> getTeacherAssignments() async {
    if (await _networkInfo.isConnected) {
      try {
        final assignments = await _remoteDataSource.getTeacherAssignments();
        await _localDataSource.cacheAssignments(
          assignments.map(_toCacheJson).toList(),
        );
        return Right(assignments);
      } on ServerException catch (error) {
        return Left(ServerFailure(error.message));
      }
    }

    try {
      final cached = await _localDataSource.getCachedAssignments();
      return Right(cached.map(AssignmentModel.fromJson).toList());
    } on CacheException catch (error) {
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

  @override
  ResultFuture<AssignmentEntity> createAssignment(
    CreateAssignmentParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final assignment = await _remoteDataSource.createAssignment(params);
      return Right(assignment);
    } on AppAuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<AssignmentEntity> updateAssignment(
    String id,
    CreateAssignmentParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final assignment = await _remoteDataSource.updateAssignment(id, params);
      return Right(assignment);
    } on AppAuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteAssignment(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.deleteAssignment(id);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<ClassOptionEntity>> getClassOptions() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final options = await _remoteDataSource.getClassOptions();
      return Right(options);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<ClassOptionEntity>> getAllClassOptions() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final options = await _remoteDataSource.getAllClassOptions();
      return Right(options);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubjectOptionEntity>> getSubjectOptions() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final options = await _remoteDataSource.getSubjectOptions();
      return Right(options);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentSubmissionEntity>> getAssignmentSubmissions(
    AssignmentSubmissionsParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final submissions = await _remoteDataSource.getAssignmentSubmissions(
        assignmentId: params.assignmentId,
        classId: params.classId,
      );
      return Right(submissions);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentAssignmentEntity>> getStudentAssignments() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final assignments = await _remoteDataSource.getStudentAssignments();
      return Right(assignments);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid createSubmission(CreateSubmissionParams params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.createSubmission(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubmissionAnnotationEntity>> getSubmissionAnnotations(
    String submissionId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final annotations = await _remoteDataSource.getSubmissionAnnotations(
        submissionId,
      );
      return Right(annotations);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<SubmissionAnnotationEntity> addAnnotation(
    AddAnnotationParams params,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final annotation = await _remoteDataSource.addAnnotation(params);
      return Right(annotation);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid updateAnnotationText(String annotationId, String text) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.updateAnnotationText(annotationId, text);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteAnnotation(String annotationId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.deleteAnnotation(annotationId);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid gradeSubmission(GradeSubmissionParams params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.gradeSubmission(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<AssignmentEntity>> getTeacherCbts() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final cbts = await _remoteDataSource.getTeacherCbts();
      return Right(cbts);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentAssignmentEntity>> getStudentCbts() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final cbts = await _remoteDataSource.getStudentCbts();
      return Right(cbts);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<AssignmentEntity> createCbt(CreateCbtInput input) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final cbt = await _remoteDataSource.createCbt(input);
      return Right(cbt);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<AssignmentEntity> updateCbt(UpdateCbtInput input) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final cbt = await _remoteDataSource.updateCbt(input);
      return Right(cbt);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<QuestionEntity>> getQuestions(String assignmentId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final questions = await _remoteDataSource.getQuestions(assignmentId);
      return Right(questions);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid submitCbtAnswers(SubmitCbtParams params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.submitCbtAnswers(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubmissionAnswerEntity>> getSubmissionAnswers(
    String submissionId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      final answers = await _remoteDataSource.getSubmissionAnswers(
        submissionId,
      );
      return Right(answers);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid gradeCbtAnswers(List<CbtAnswerGrade> grades) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }

    try {
      await _remoteDataSource.gradeCbtAnswers(grades);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }
}
